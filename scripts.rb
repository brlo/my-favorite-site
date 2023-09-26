# рестарт web-сервера
touch tmp/restart.txt

# очистка поискового кэша
rm ./db/cache_search/*/*/*.json


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





# ПОИСК НАИБОЛЕЕ ВСТРЕЧАЮЩИХСЯ СЛОВ


# regex doc: https://www.php.net/manual/fr/function.preg-match.php#105324

# # GREEK - regexp: a-zA-Z\p{Greek}
h=Hash.new(0);Verse.where(lang: :'gr-lxx-byz').each{|v| v.t.to_s.gsub(/[^A-Za-zΑ-Ωα-ωίϊΐόάέύϋΰήώ\s]/i, '').split(' ').each {|w| puts(w); w.length > 2 ? h[w] += 1 : nil}};nil
h=Hash.new(0);Verse.where(lang: :'gr-lxx-byz').each{|v| v.t.to_s.gsub(/[^\p{Alpha}\s]/i, '').split(' ').each {|w| w.length > 2 ? h[w] += 1 : nil}};nil

h.select{|k,v| k.length > 4}.sort_by{|k,v| v}.last(40).reverse.to_h

# RU - regexp: a-zA-Z\p{Cyrilic}
h=Hash.new(0);Verse.where(lang: :'ru').each{|v| v.t.to_s.gsub(/[^\p{Alpha}\s]/i, '').split(' ').each {|w| w.length > 3 ? h[w] += 1 : nil}};h.select{|k,v| k.length > 4}.sort_by{|k,v| v}.last(40).reverse.to_h

# =>
# {
#   "αὐτοῦ"      => 9770,
#   "αὐτῶν"      => 5303,
#   "κύριος"     => 3564,
#   "εἶπεν"      => 3225,
#   "Ισραηλ"     => 2702,
#   "κυρίου"     => 2638,
#   "αὐτὸν"      => 2461,
#   "αὐτῆς"      => 2064,
#   "αὐτοῖς"     => 1914,
#   "αὐτοὺς"     => 1617,
#   "πάντα"      => 1520,
#   "ἐστιν"      => 1489,
#   "ἔσται"      => 1367,
#   "τοῦτο"      => 1089,
#   "Δαυιδ"      => 1083,
#   "αὐτόν"      => 1081,
#   "λέγει"      => 1068,
#   "λέγων"      => 970,
#   "βασιλεὺς"   => 936,
#   "ἐγένετο"    => 921,
#   "κυρίῳ"      => 894,
#   "ἡμέρας"     => 890,
#   "οὕτως"      => 849,
#   "αὐτούς"     => 849,
#   "βασιλέως"   => 825,
#   "Ιερουσαλημ" => 815,
#   "ταῦτα"      => 798,
#   "πάντες"     => 795,
#   "ἐποίησεν"   => 773,
#   "ἡμέρᾳ"      => 771,
#   "αὐτὴν"      => 755,
#   "ἔστιν"      => 740,
#   "κύριον"     => 715,
#   "Ιουδα"      => 677,
#   "οἶκον"      => 656,
#   "αὐτὸς"      => 641,
#   "Ἰησοῦς"     => 629,
#   "ὄνομα"      => 590,
#   "κύριε"      => 585,
#   "προσώπου"   => 571
# }




# Приведение в порядок нумерации стихов, где вынесен в стих-0 заголок
# в каждом языке
%w(ru csl-pnm csl-ru eng-nkjv heb-osm gr-lxx-byz).each do |lang|
  books_ids = Verse.where(lang: 'ru').distinct(:bid)

  # в каждой книге
  books_ids.each do |book_id|
    chapters = Verse.where(lang: 'ru', bid: book_id).distinct(:ch)

    if chapters.sort != (1..chapters.max).to_a
      raise('chapters wrong: ' + chapters.sort.to_s)
    end

    # в каждой главе
    chapters.each do |chapter|
      lines = Verse.where(lang: lang, bid: book_id, ch: chapter, :l.nin => [0]).distinct(:l)

      # где не меньше 3-х строк
      next if lines.count <= 3

      if lines.sort != (1..lines.max).to_a
        if lines.sort == (2..lines.max).to_a
          # в главе есть все стихи, кроме первого, значит просто смещаем все номера на 1 вниз
          # puts
          # puts '==========='
          # puts '==========='
          # puts Verse.where(lang: lang, bid: book_id, ch: chapter, :l.nin => [0]).order(l: 1).first.inspect
          Verse.where(lang: lang, bid: book_id, ch: chapter, :l.nin => [0,1]).order(l: 1).each do |v|
            v.line = v.line - 1
            v.address = nil
            v.save!
          end
        elsif lines.sort == (3..lines.max).to_a
          # в главе есть все стихи, кроме 1 и 2, значит просто смещаем все номера на 2 вниз
          # puts
          # puts '==========='
          # puts '==========='
          # puts Verse.where(lang: lang, bid: book_id, ch: chapter, :l.nin => [0]).order(l: 1).first.inspect
          Verse.where(lang: lang, bid: book_id, ch: chapter, :l.nin => [0,1,2]).order(l: 1).each do |v|
            v.line = v.line - 2
            v.address = nil
            v.save!
          end
        else
          raise('lines wrong: ' + lines.sort.to_s)
        end
      end
    end
  end
end; nil

# В указанных главах вынести первый стих в нулевой
books = %w(ru csl-pnm csl-ru eng-nkjv heb-osm gr-lxx-byz)

lang = 'ru'
book = 'ps'
chapters = (3..9).to_a
chapters.map {|ch| v=Verse.where(lang: lang, bc: book, ch: ch, l: 1).first; v.update!(a: nil, l: 0); v.text }

# вынесение в 0-стих первых двух стихов
ch = 50
v1=Verse.where(lang: lang, bc: book, ch: ch, l: 1).first; nil
v2=Verse.where(lang: lang, bc: book, ch: ch, l: 2).first; nil
v1.update!(a: nil, l: 0, t: v1.t + ' ' + v2.t); v1.text
v2.delete

# кол-во стихов
Verse.where(lang: 'ru', bc: 'ps').count

# копирование книги между языками
Verse.where(lang: 'ru', bc: 'ps').each{|v| Verse.create!(lang: 'csl-ru', bid: v.bid, bc: 'ps', ch: v.ch, l: v.l, t: v.t) }

# Удаление книги
Verse.where(lang: 'ru', bc: 'ps').each(&:delete)

# импорт одной книги из sql
ImportVerse.where(book_number: 230).each{|v| Verse.create!(lang: 'ru', bid: 230, bc: 'ps', ch: v.chapter.to_i, l: v.verse.to_i, t: v.text) };nil

# поиск в синодальном тексте заголовков в скобках { }, кроме строк со {Слава:}
Verse.where(t: /{.+}/i).to_a.reject{|v| v.t=~/{Слава:}/}.each do |v|
  title = v.text.scan(/{(.+)}/).first&.first
  Verse.create!(lang: v.lang, bid: v.bid, bc: v.bc, ch: v.ch, l: 0, t: title)
  clean_line = v.text.gsub(/\s?{.+}\s?/, '')
  v.text = clean_line
  v.save!
end; nil

# объединение 0 и 2 стихов, удаление 2 стиха
ch = 51
v0 = Verse.where(lang: lang, bc: book, ch: ch, l: 0).first
v2 = Verse.where(lang: lang, bc: book, ch: ch, l: 2).first
v0.update!(t: v0.t + ' ' + v2.t)
v2.delete

# разгруппировка сгруппированных стихов по следующим пустым строкам.
# Короче, в один стих почему-то засунули несколько стихов и вначале обозначили промежуток номеров стихов:
# "5-9 потом текст". Надо разгруппировать, разбить по точкам и распихать как получится по следующим пустым
# строкам, в которых записана просто точка.
# поиск в синодальном тексте заголовков в скобках { }, кроме строк со {Слава:}
Verse.where(lang: 'ge-gnb').where(t: /^\s*[0-9]+\-[0-9]+/i).each do |v|
  # find range
  from, to = v.text.scan(/([0-9]+)\-([0-9]+)/).first

  # raise if range not start from current line

  if from.to_i != v.l.to_i
    puts("from: #{from}")
    puts("to: #{to}")
    puts("v.l: #{v.l}")
    puts("v: #{v.inspect}")
    raise('AAA')
  end

  # remove range
  text = v.text.gsub(/([0-9]+)\-([0-9]+)/, '')

  # делим на предложения, чистим пробелы, добавляем в конец предложений точки
  sentences = text.split('.').map(&:strip).map{|s| s+'.' }

  # считаем сколько предложений попадёт в каждый следующий стих.
  # next lines: [5,6,7,8,9]
  lines = (from..to).to_a
  lines=Verse.where(lang: v.lang, bid: v.bid, bc: v.bc, ch: v.ch, :l.in => lines).pluck(:l)
  puts "---"
  puts "lines: #{lines}"
  raise('no lines') if lines.empty?
  sent_in_lines = {}
  lines.each { |l| sent_in_lines[l] = 0 }

  i = 0
  loop do
    puts "lines: #{lines}"
    puts "sentences.count: #{sentences.count}"
    puts "i: #{i}"
    puts
    lines.each do |l|
      # если все предложения раскидали — выходим
      break if sentences.count == i
      sent_in_lines[l]+=1
      i+=1
    end

    break if sentences.count == i
  end

  i=0
  sent_in_lines.each do |line, sent_count|
    next if sent_count < 1
    break if sentences.blank?
    text = sentences.shift(sent_count).join(' ')
    vers=Verse.where(lang: v.lang, bid: v.bid, bc: v.bc, ch: v.ch, l: line).first
    puts "v: #{v.inspect}"
    raise('no verse found') unless vers
    if i==0
      vers.text = text
      vers.save!
    else
      if vers.text = '.'
        vers.text = text
        vers.save!
      else
        puts "text: #{text}"
        puts "vers.inspect: #{vers.inspect}"
        raise
      end
    end
    i+=1
  end

  # break
end; nil








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
