# ПРИВЕДЕНИЕ СТИХОВ И НУМЕРАЦИИ В ПОРЯДОК

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


