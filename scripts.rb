# очистка поискового кэша
rm ./db/cache_search/*/*/*.json

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

# поиск в синодатльном тексте заголовков в скобках { }, кроме строк со {Слава:}
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


# СТАРОЕ


# FROM OLD MODEL TO NEW
# ::Stih.each do |s|
#   ::Verse.create!(lang: 'ru', book: s.book, chapter: s.chapter, line: s.number, text: s.text)
# end

# НАЙТИ ПУСТЫЕ СТИХИ
# ImportVerse.where(text: ['', nil]).map{|v| [v.book_number.to_i, v.chapter.to_i, v.verse.to_i, v.text]}

# Add book_id
# Verse.all.each { |v| v.update(bid: BOOKS[v.book][:id]) }

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
