# ИМПОРТ НОВОГО ПЕРЕВОДА ИЗ SQLite в Mongo

# ###############################################################################
# FROM SQLite to Mongo
# https://github.com/rails/rails-html-sanitizer
# ###############################################################################

sanitizer = Rails::Html::SafeListSanitizer.new
books_id_code = ::BOOKS.map { |code, data| [data[:id], code] }.to_h
lang = 'cn-ccbs' # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ПОПРАВИТЬ ТОЛЬКО ТУТ
::ImportVerse.all.order('verses.id').find_each do |s|
  # только для иврита пропускаем. Там вконце несколько строк пустых.
  s.text = '.' if s.text.blank?

  book = books_id_code[s.book_number.to_i]
  book_info = ::BOOKS[book]
  next if book_info.nil?
  id = book_info[:id]
  zavet = book_info[:zavet]

  # удаляем что-то <f>
  str = s.text.dup.gsub(/<f>[^<f>]+<\/f>/, '')
  # удаляем стронг
  str = str.gsub(/<S>[^<S>]+<\/S>/, '')
  # что-то непонятное
  str = str.gsub(/<m>[^<m>]+<\/m>/, '')
  # заменяем красвые кавычки «» на обычные "
  str = str.gsub(/[«»]/, '"')
  # Перенос строки <br/> на пробел
  str = str.gsub(/<br\/>/, ' ')

  # убираем лишние тэги
  str = sanitizer.sanitize(str, tags: %w(i j br))

  # удалить множественные пробелы
  str = str.gsub(/[\s\t\n\r]+/, ' ')
  # удалить пробел в начале и в конце
  str = str.gsub(/^\s|\s$/, '')

  # # меняем "| слово | VAR: слово2 |" на просто "слово2" (слово2 как на Азбуке)
  # str = str.gsub(/\|[^\|]+\| VAR:([^\|]+)\|/i, '\1')

  v = Verse.find_or_initialize_by(lang: lang, bid: id, chapter: s.chapter.to_i, line: s.verse.to_i)
  v.update!(book: book, zavet: zavet, text: str, data: {'orig': s.text})
end

# ###############################################################################


 # ПОСЛЕ ЗАГРУЗКИ ПЕРЕВОДА В ЛОКАЛЬНУЮ БАЗУ И ПРИВЕДЕНИЯ ЕГО В ПОРЯДОК
 # ИМПОРТИРУЙ НОВЫЕ ДАННЫЕ С ПОМЩЬЮ ПРИЛОЖЕНИЯ Studio 3T
 # Там есть импорт и экспорт данных.
 # Для импорта используй запрос { "lang" : { "$in" : [ "jp-ni", "cn-ccbs", "arab-avd", "ge-sch" ] } }
 # поставь нужные новые языки в массив.






# ======================================================
# МИГРАЦИЮ КНИГИ ИЗ SQLite смотри в конце модели Verse
# ======================================================

# СТАРОЕ


# FROM OLD MODEL TO NEW
# ::Stih.each do |s|
#   ::Verse.create!(lang: 'ru', book: s.book, chapter: s.chapter, line: s.number, text: s.text)
# end

# НАЙТИ ПУСТЫЕ СТИХИ
# ImportVerse.where(text: ['', nil]).map{|v| [v.book_number.to_i, v.chapter.to_i, v.verse.to_i, v.text]}

# Add book_id
# Verse.all.each { |v| v.update(bid: BOOKS[v.book][:id]) }

# ПРОСТАВИТЬ ВЕТХИЙ И НОВЫЙ ЗАВЕТ
# veth = BOOKS.select{ |book,params| params[:zavet] == 1 }.keys
# Verse.where(:book.in => veth).update_all(zavet: 1)

# nov = BOOKS.select{ |book,params| params[:zavet] == 2 }.keys
# Verse.where(:book.in => nov).update_all(zavet: 2)


# # Поиск в Псалтири стихов, разделённых двумя <br>
# # Создание из первой части нового нулевого стиха как подпись псалма.
# # А второй кусок становиться новым текстом первого стиха
# Verse.where(book: 'ps', :lang.nin => ["gr-lxx-byz"]).where(text: /<br\/?>/i).to_a.each do |v|
#   splits = v.text.split(/<br\/?>/)
#   splits = splits.reject{ |s| s.length < 3}
#   raise('Wow! ' + v.inspect) if splits.count != 2

#   zero_text = splits.first.strip
#   first_text = splits.last.strip
#   puts zero_text, first_text

#   zero = Verse.create!(lang: v.lang, bc: v.bc, bid: v.bid, ch: v.ch, l: 0, z: v.z, t: zero_text, data: {orig: zero_text})
#   v.update!(t: first_text, data: {orig: first_text})
# end; nil

# ---------------------------------------------------------------------
# # Вычленяем 0-й стих из первого стиха в греческой версии Псалтири
# Verse.where(book: 'ps', :lang => "gr-lxx-byz").where(l: 1, text: /1/i).to_a.each do |v|
#   splits = v.text.split(/1/)
#   # splits = splits.reject{ |s| s.length < 3}
#   next if splits.count != 2

#   zero_text = splits.first.strip
#   first_text = splits.last.strip
#   puts zero_text, first_text
#   puts '---'

#   zero = Verse.create!(lang: v.lang, bc: v.bc, bid: v.bid, ch: v.ch, l: 0, z: v.z, t: zero_text, data: {orig: zero_text})
#   v.update!(t: first_text, data: {orig: first_text})
# end; nil

# ---------------------------------------------------------------------
# # Вычленяем 0-й стих из первого стиха в английской версии Псалтири
# Verse.where(book: 'ps', :lang => "eng-nkjv").where(l: 1, text: /\[1\]/i).to_a.each do |v|
#   splits = v.text.split(/\[1\]/)
#   # splits = splits.reject{ |s| s.length < 3}
#   raise('Wow! ' + v.inspect) if splits.count != 2

#   zero_text = splits.first.strip
#   first_text = splits.last.strip
#   puts zero_text, first_text
#   puts '---'

#   zero = Verse.create!(lang: v.lang, bc: v.bc, bid: v.bid, ch: v.ch, l: 0, z: v.z, t: zero_text, data: {orig: zero_text})
#   v.update!(t: first_text, data: {orig: first_text})
# end; nil
