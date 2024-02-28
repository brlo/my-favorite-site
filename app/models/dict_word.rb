# db.createUser({ user: 'bibl_explorer', pwd: '123', roles: [ { role: "readWrite", db: "biblia_production" } ] });
# DictWord.create_indexes

class DictWord < ApplicationMongoRecord

  DICTS = {
    'd' => {'name' => 'Дворецкий', 'from' => 'gr', 'to' => 'ru'},
    'w' => {'name' => 'Вайсмен', 'from' => 'gr', 'to' => 'ru'},
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

    self.word = self.word.to_s.strip.delete("\u0302-\u036F").presence.gsub(/[\t\s\n\r]+/, ' ').unicode_normalize(:nfd).downcase.delete("\u0302-\u036F").presence
    self.sinonim = self.sinonim.to_s.strip.gsub(/[\t\s\n\r]+/, ' ').unicode_normalize(:nfd).downcase.delete("\u0302-\u036F").presence
    self.lexema = self.lexema.to_s.strip.gsub(/[\t\s\n\r]+/, ' ').unicode_normalize(:nfd).downcase.delete("\u0302-\u036F").presence
    # word уже в нижнем регистре и без диакрит. знаков, но тут мы убираем даже ударения.
    # Это важно, потому что Люба добавляет слова без ударений
    self.word_simple = self.word.delete('-').delete("\u0300-\u036F").presence
    self.transcription = self.transcription.to_s.strip.gsub(/[\t\s\n\r]+/, ' ').presence
    self.translation_short = self.translation_short.to_s.strip.gsub(/[\t\s\n\r]+/, ' ').downcase.presence
    self.translation = self.translation.to_s.strip.gsub(/[\t\s\n\r]+/, ' ').presence

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
end
