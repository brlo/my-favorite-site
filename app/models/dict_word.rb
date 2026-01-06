class DictWord < ApplicationRecord
  DICTS = {
    'd' => {'name' => 'Дворецкий И.Х.', 'from' => 'gr', 'to' => 'ru'},
    'w' => {'name' => 'Вейсман А.Д.', 'from' => 'gr', 'to' => 'ru'},
    'bbx' => {'name' => 'Bibleox', 'from' => 'gr', 'to' => 'ru'},
    't' => {'name' => 'Тестовый', 'from' => 'jp', 'to' => 'ru'},
  }

  self.table_name = 'dict_words'

  # dict       - d (d - Дворецкий, w - Вайсман, bbx - словарь для собственных определений (результат исследований))
  # word       - εὐθεώρητος
  # desc       -
  #   <h>εὐ-θεώρητος 2</h>
  #   <n>1)</n> легко заметный, хорошо видимый <a>Arst., Plut.</a>;
  #   <n>2)</n> легко воспринимаемый, ощутительный <a>Arst., Plut.</a>

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
      created_at:        self.created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      updated_at:        self.updated_at&.strftime("%Y-%m-%d %H:%M:%S"),
      updated_at_word:   self.updated_at_word,
    }
  end

  def normalize_attributes
    # если словарь неизвестен, то обнуляем его, при сохранении споткнётся об валидацию наличия
    self.dict = nil if !DICTS.has_key?(self.dict)

    # замена каких-либо пустот на пробелы
    # .gsub(/[\t\s\n\r]+/, ' ')
    self.word = self.word.to_s.unicode_normalize(:nfd).strip
    self.sinonim = self.class.word_clean_gr(self.sinonim)
    self.lexema = self.class.word_clean_gr(self.lexema)

    # word уже в нижнем регистре и без диакрит. знаков, но тут мы убираем даже ударения.
    # Это важно, потому что Люба добавляет слова без ударений
    self.word_simple = self.class.word_clean_gr(self.word)
    self.word_simple_no_endings = self.class.remove_greek_ending(self.word_simple)
    self.transcription = self.transcription.to_s.gsub(/[\t\s\n\r]+/, ' ').strip.presence
    self.translation_short = self.translation_short.to_s.gsub(/[\t\s\n\r]+/, ' ').strip.presence
    self.translation = self.translation.to_s.gsub(/[\t\s\n\r]+/, ' ').strip.presence

    # if self.word.present? && self.word_simple.blank?
    #   # a="άέήίϊϋόύώἀἁἂἃἄἅἆἐἑἓἔἕἠἡἢἣἤἥἦἧἰἱἳἴἵἶἷὀὁὂὃὄὅὐὑὒὓὔὕὖὗὠὡὢὤὥὦὧὰάὲέὴήὶίὸόὺύὼώᾀᾄᾅᾆᾐᾑᾔᾖᾗᾠᾤᾧᾳᾴᾶᾷῃῄῆῇῒΐῖῢΰῥῦῳῴῶῷ"; a=a+a.upcase
    #   # b="αεηιιυουωαααααααεεεεεηηηηηηηηιιιιιιιοοοοοουυυυυυυυωωωωωωωααεεηηιιοουυωωααααηηηηηωωωααααηηηηιιιυυρυωωωω"; b=b+b.upcase
    #   # self.word_simple = self.word.tr(a, b)
    #   self.word_simple = self.word.unicode_normalize(:nfd).downcase.delete("\u0300\u0302-\u036F")
    # end

    self.desc = sanitizer.sanitize(
      self.desc.to_s,
      tags: ::Page::ALLOW_TAGS,
      attributes: ::Page::ALLOW_ATTRS,
    )
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
    # 1-2 символа не трогаем, итак уже почти ничего не осталось, куда ещё окончание удалять
    return w if w.to_s.length < 3

    _w = w.to_s.gsub(/(ματος|ματων|ματα|ιους|ιου|ιων|ιας|ιες|ιων|ιοι|ους|οι|ου|ον|μα|ων|ης|ος|ας|ες|ια|ι|α|η|ο|ε|υ)$/i, '~').strip
    # отдаём слово без окончания только если остаток от слова: 3 и более символов
    _w.length >= 3 ? _w.presence : w
  end

  def self.find_simple(word)
    w1 = word_clean_gr(word)
    w2 = remove_greek_ending(w1)

    where(word_simple: w1).or(where(word_simple_no_endings: w2)).to_a
  end

  def search_dict_words(term)
    term = term.gsub(/[^[[:alnum:]]\s]/, '')
    term = ::DictWord.word_clean_gr(term)

    # Поля, по которым ищем
    fields = %i[word_simple sinonim lexema tag transcription transcription_lat translation_short translation]

    # Строим условия: поле ILIKE 'term%'
    conditions = fields.map { |field| where("LOWER(#{field}) LIKE LOWER(?)", "#{term}%") }

    # Объединяем условия через OR
    query = conditions.reduce(:or)

    @dict_words = query.order(:word)
  end
end
