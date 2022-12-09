# db.createUser({ user: 'bibl_explorer', pwd: '123', roles: [ { role: "readWrite", db: "biblia_production" } ] });
# Verse.create_indexes

class Verse
  include Mongoid::Document

  # lang       - ru
  # address    - zah:9:8
  # zavet      - 1
  # book_id    - 10
  # book       - zah
  # chapter    - 9
  # line       - 8
  # text       - текст стиха
  # data       - спец. параметры
  # created_at - дата-время-создания

  # язык
  field :lang, type: String
  # код стиха
  field :a, as: :address, type: String
  # Завет (1 или 2)
  field :z, as: :zavet, type: Integer
  # id книги (для сортировки)
  field :bid, as: :book_id, type: Integer
  # код книги
  field :bc, as: :book, type: String
  # номер главы
  field :ch, as: :chapter, type: Integer
  # номер стиха
  field :l, as: :line, type: Integer
  # текст стиха
  field :t, as: :text, type: String
  # запасное поле для параметров
  field :data, type: Hash
  # время создания можно получать из _id во так: id.generation_time
  field :c_at, as: :created_at, type: DateTime, default: ->{ DateTime.now.utc.round }

  # rake db:mongoid:create_indexes
  # rake db:mongoid:remove_indexes
  # rake db:mongoid:remove_undefined_indexes
  # для поиска в нужной книге
  index({lang: 1, book: 1},                      {background: true})
  # для поиска в нужном завете
  index({lang: 1, zavet: 1},                     {background: true})
  # для отдачи нужной главы
  index({lang: 1, book: 1, ch: 1},               {background: true})
  # чтобы не создавались одинаковые стихи
  index({lang: 1, book_id: 1, ch: 1, line: 1},   {unique: true, background: true})
  # для поиска по тексту
  index({lang: 1, text: 'text'},                 {background: true})

  validates :lang, :address, :book_id, :book, :chapter, :line, :text, presence: true

  before_validation :set_address_if_nil

  def set_address_if_nil
    if self.address.nil?
      if book && chapter && line
        self.address = "#{book}:#{chapter}:#{line}"
      else
        raise('Verse must contain Book, Chapter and Line')
      end
    end
  end
end


# ###############################################################################
# FROM SQLite to Mongo
# https://github.com/rails/rails-html-sanitizer
# ###############################################################################

# sanitizer = Rails::Html::SafeListSanitizer.new
# books_id_code = ::BOOKS.map { |code, data| [data[:id], code] }.to_h
# lang = 'gr-lxx-byz'
# ::ImportVerse.all.order('verses.id').find_each do |s|
#   # только для иврита пропускаем. Там вконце несколько строк пустых.
#   s.text = '.' if s.text.blank?

#   book = books_id_code[s.book_number.to_i]
#   book_info = ::BOOKS[book]
#   next if book_info.nil?
#   id = book_info[:id]
#   zavet = book_info[:zavet]

#   # удаляем что-то <f>
#   str = s.text.dup.gsub(/<f>[^<f>]+<\/f>/, '')
#   # удаляем стронг
#   str = str.gsub(/<S>[^<S>]+<\/S>/, '')
#   # что-то непонятное
#   str = str.gsub(/<m>[^<m>]+<\/m>/, '')

#   # убираем лишние тэги
#   str = sanitizer.sanitize(str, tags: %w(i j br))

#   # удалить множественные пробелы
#   str = str.gsub(/[\s\t\n\r]+/, ' ')
#   # удалить пробел в начале и в конце
#   str = str.gsub(/^\s|\s$/, '')

#   # меняем "| слово | VAR: слово2 |" на просто "слово2" (слово2 как на Азбуке)
#   str = str.gsub(/\|[^\|]+\| VAR:([^\|]+)\|/i, '\1')

#   v = Verse.find_or_initialize_by(lang: lang, bid: id, chapter: s.chapter.to_i, line: s.verse.to_i)
#   v.update!(book: book, zavet: zavet, text: str, data: {'orig': s.text})
# end

# ###############################################################################
