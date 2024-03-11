# db.createUser({ user: 'bibl_explorer', pwd: '123', roles: [ { role: "readWrite", db: "biblia_production" } ] });
# DictWord.create_indexes

class DictWord < ApplicationMongoRecord

  DICTS = {
    'd' => {'name' => 'Дворецкий И.Х.', 'from' => 'gr', 'to' => 'ru'},
    'w' => {'name' => 'Вейсман А.Д.', 'from' => 'gr', 'to' => 'ru'},
    'dmt' => {'name' => 'Дьячок М.Т.', 'from' => 'gr', 'to' => 'ru'},
    't' => {'name' => 'Тестовый', 'from' => 'jp', 'to' => 'ru'},
  }

  include Mongoid::Document
  # dict       - d (d - Дворецкий, w - Вайсман, c - custom)
  # word       - εὐθεώρητος
  # desc       -
  #   <h>εὐ-θεώρητος 2</h>
  #   <n>1)</n> легко заметный, хорошо видимый <a>Arst., Plut.</a>;
  #   <n>2)</n> легко воспринимаемый, ощутительный <a>Arst., Plut.</a>
  # created_at - дата-время-создания

  # Словарь (Дворецкого, Вайсмана)
  field :dict, type: String
  # Слово
  field :w,   as: :word, type: String
  # Слово, записанное без доп.знаков (для поиска)
  field :ws,  as: :word_simple, type: String
  # Слово, записанное без доп.знаков и без окончаний (для поиска)
  field :wse,  as: :word_simple_no_endings, type: String
  # Синоним
  field :sin, as: :sinonim, type: String
  # Лексема
  field :lx,  as: :lexema, type: String
  # Чтение
  field :t,   as: :transcription, type: String
  # Чтение латинскими буквами
  field :tl,  as: :transcription_lat, type: String
  # Перевод короткий (может быть для подстрочника)
  field :trs, as: :translation_short, type: String
  # Перевод
  field :tr,  as: :translation, type: String
  # Главный признак (сущ., гл., прил., вопрос, мест.)
  field :tag, as: :tag, type: String
  # Описание слова
  field :desc, type: String
  # время создания можно получать из _id во так: id.generation_time
  field :c_at, as: :created_at, type: DateTime, default: ->{ DateTime.now.utc.round }
  field :u_at, as: :updated_at, type: DateTime, default: ->{ DateTime.now.utc.round }

  # DictWord.remove_indexes
  # DictWord.create_indexes
  # DictWord.remove_undefined_indexes
  index({dict: 1}, {background: true})
  index({ws: 1},   {background: true})
  index({tag: 1},  {background: true})

  before_validation :normalize_attributes

  validates :dict, :word, :word_simple, presence: true

  def attrs_for_render
    {
      id:                self.id.to_s,
      dict:              self.dict,
      dict_name:         DICTS[self.dict]['name'],
      src_lang:          DICTS[self.dict]['from'],
      dst_lang:          DICTS[self.dict]['to'],
      word:              self.word,
      sinonim:           self.sinonim,
      lexema:            self.lexema,
      transcription:     self.transcription,
      transcription_lat: self.transcription_lat,
      translation_short: self.translation_short,
      translation:       self.translation,
      tag:               self.tag,
      desc:              self.desc,
      created_at:        self.c_at&.strftime("%Y-%m-%d %H:%M:%S"),
      updated_at:        self.u_at&.strftime("%Y-%m-%d %H:%M:%S"),
      updated_at_word:   self.updated_at_word,
    }
  end

  def normalize_attributes
    # если словарь неизвестен, то обнуляем его, при сохранении споткнётся об валидацию наличия
    self.dict = nil if !DICTS.has_key?(self.dict)

    # замена каких-либо пустот на пробелы
    # .gsub(/[\t\s\n\r]+/, ' ')
    self.word = self.class.word_clean_diacritic_only_gr(self.word)
    self.sinonim = self.class.word_clean_diacritic_only_gr(self.sinonim)
    self.lexema = self.class.word_clean_diacritic_only_gr(self.lexema)

    # word уже в нижнем регистре и без диакрит. знаков, но тут мы убираем даже ударения.
    # Это важно, потому что Люба добавляет слова без ударений
    self.word_simple = self.class.word_clean_gr(self.word)
    self.word_simple_no_endings = self.class.remove_greek_ending(self.word_simple)
    self.transcription = self.transcription.to_s.gsub(/[\t\s\n\r]+/, ' ').strip.presence
    self.translation_short = self.translation_short.to_s.gsub(/[\t\s\n\r]+/, ' ').downcase.strip.presence
    self.translation = self.translation.to_s.gsub(/[\t\s\n\r]+/, ' ').strip.presence

    # if self.word.present? && self.word_simple.blank?
    #   # a="άέήίϊϋόύώἀἁἂἃἄἅἆἐἑἓἔἕἠἡἢἣἤἥἦἧἰἱἳἴἵἶἷὀὁὂὃὄὅὐὑὒὓὔὕὖὗὠὡὢὤὥὦὧὰάὲέὴήὶίὸόὺύὼώᾀᾄᾅᾆᾐᾑᾔᾖᾗᾠᾤᾧᾳᾴᾶᾷῃῄῆῇῒΐῖῢΰῥῦῳῴῶῷ"; a=a+a.upcase
    #   # b="αεηιιυουωαααααααεεεεεηηηηηηηηιιιιιιιοοοοοουυυυυυυυωωωωωωωααεεηηιιοουυωωααααηηηηηωωωααααηηηηιιιυυρυωωωω"; b=b+b.upcase
    #   # self.word_simple = self.word.tr(a, b)
    #   self.word_simple = self.word.unicode_normalize(:nfd).downcase.delete("\u0300\u0302-\u036F")
    # end

    self.desc = sanitizer.sanitize(
      self.desc.to_s,
      tags: ::Page::ALLOW_TAGS
    )

    self.u_at = DateTime.now.utc.round
  end

  # удаляем все диакритические знаки и все три ударения: оксия, вария, периспоменон
  def self.word_clean_gr w
    w.to_s.unicode_normalize(:nfd).downcase.delete("\u0300-\u036F").gsub(/[^\p{L}\s]/, '').strip.presence
  end

  # чистим слово от диакритических знаков, но оставляем три ударения: оксия, вария, периспоменон.
  # тут в delete пропускаем прямое и обратное ударение u0300-u0301, а также волнистое (долгое) ударение u0342
  def self.word_clean_diacritic_only_gr w
    w.to_s.unicode_normalize(:nfd).downcase.delete("\u0302-\u0341\u0343-\u036F").gsub(/[^\p{L}\s]/, '').strip.presence
  end

  # убирает все возможные греческие окончания
  # TODO: возможно, этот же приём стоит применить в Lexema
  def self.remove_greek_ending w
    return w if w.to_s.length < 3

    _w = w.to_s.gsub(/(ματος|ματων|ματα|ιους|ιου|ιων|ιας|ιες|ιων|ιοι|ους|οι|ου|ον|μα|ων|ης|ος|ας|ες|ια|ι|α|η|ο|ε|υ)$/i, '~').strip
    _w.length > 3 ? _w.presence : w
  end

  def self.find_simple(word)
    w1 = word_clean_gr(word)
    w2 = remove_greek_ending(w1)

    self.or(word_simple: w1, word_simple_no_endings: w2).to_a
  end
end
