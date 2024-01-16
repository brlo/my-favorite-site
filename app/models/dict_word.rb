# db.createUser({ user: 'bibl_explorer', pwd: '123', roles: [ { role: "readWrite", db: "biblia_production" } ] });
# DictWord.create_indexes

class DictWord < ApplicationMongoRecord
  include Mongoid::Document
  # dict       - d (d - Дворецкий, w - Вайсман)
  # word       - εὐθεώρητος
  # desc       -
  #   <h>εὐ-θεώρητος 2</h>
  #   <n>1)</n> легко заметный, хорошо видимый <a>Arst., Plut.</a>;
  #   <n>2)</n> легко воспринимаемый, ощутительный <a>Arst., Plut.</a>
  # created_at - дата-время-создания

  # Словарь (Дворецкого, Вайсмана)
  field :dict, type: String
  # Языки
  field :sl, as: :src_lang, type: String
  field :dl, as: :dst_lang, type: String
  # Слово
  field :w, as: :word, type: String
  # Слово, записанное без доп.знаков
  field :ws, as: :word_simple, type: String
  # Чтение
  field :t, as: :transcription, type: String
  # Перевод короткий (может быть для подстрочника)
  field :trs, as: :translation_short, type: String
  # Перевод
  field :tr, as: :translation, type: String
  # Описание слова
  field :desc, type: String
  # время создания можно получать из _id во так: id.generation_time
  field :c_at, as: :created_at, type: DateTime, default: ->{ DateTime.now.utc.round }

  # DictWord.remove_indexes
  # DictWord.create_indexes
  # DictWord.remove_undefined_indexes
  index({dict: 1}, {background: true})
  index({ws: 1},   {background: true})

  validates :dict, :src_lang, :dst_lang, :word, :word_simple, :desc, presence: true

  before_validation :set_word_simple

  def set_word_simple
    if self.word.present? && self.word_simple.blank?
      a="άέήίϊϋόύώἀἁἂἃἄἅἆἐἑἓἔἕἠἡἢἣἤἥἦἧἰἱἳἴἵἶἷὀὁὂὃὄὅὐὑὒὓὔὕὖὗὠὡὢὤὥὦὧὰάὲέὴήὶίὸόὺύὼώᾀᾄᾅᾆᾐᾑᾔᾖᾗᾠᾤᾧᾳᾴᾶᾷῃῄῆῇῒΐῖῢΰῥῦῳῴῶῷ"; a=a+a.upcase
      b="αεηιιυουωαααααααεεεεεηηηηηηηηιιιιιιιοοοοοουυυυυυυυωωωωωωωααεεηηιιοουυωωααααηηηηηωωωααααηηηηιιιυυρυωωωω"; b=b+b.upcase
      self.word_simple = self.word.tr(a, b)
    end
  end

  def attrs_for_render
    {
      id:                self.id.to_s,
      dict:              self.dict,
      src_lang:          self.src_lang,
      dst_lang:          self.dst_lang,
      word:              self.word,
      transcription:     self.transcription,
      translation_short: self.translation_short,
      translation:       self.translation,
      desc:              self.desc,
      created_at:        self.c_at&.strftime("%Y-%m-%d %H:%M:%S"),
    }
  end
end
