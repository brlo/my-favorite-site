# db.createUser({ user: 'bibl_explorer', pwd: '123', roles: [ { role: "readWrite", db: "biblia_production" } ] });
# Verse.create_indexes

class Verse
  include Mongoid::Document

  # FROM OLD MODEL TO NEW
  # ::Stih.each do |s|
  #   ::Verse.create!(lang: 'ru', book: s.book, chapter: s.chapter, line: s.number, text: s.text)
  # end

  # FROM SQLite to Mongo
  # books_id_code = ::BOOKS.map { |code, data| [data[:id], code] }.to_h
  # ::ImportVerse.order('verses.id').find_each do |s|
  #   book = books_id_code[s.book_number.to_i]
  #   zavet = ::BOOKS[book][:zavet]

  #   ::Verse.create!(lang: 'csl-ru', book: book, zavet: zavet, chapter: s.chapter.to_i, line: s.verse.to_i, text: s.text)
  # end

  # НАЙТИ ПУСТЫЕ СТИХИ
  # ImportVerse.where(text: ['', nil]).map{|v| [v.book_number.to_i, v.chapter.to_i, v.verse.to_i, v.text]}

  # Add book_id
  # Verse.all.each { |v| v.update(bid: BOOKS[v.book][:id]) }

  # veth = BOOKS.select{ |book,params| params[:zavet] == 1 }.keys
  # Verse.where(:book.in => veth).update_all(zavet: 1)

  # nov = BOOKS.select{ |book,params| params[:zavet] == 2 }.keys
  # Verse.where(:book.in => nov).update_all(zavet: 2)

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
  field :lang, as: :lang, type: String
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

  validates :address, :book_id, :book, :chapter, :line, :text, presence: true

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
