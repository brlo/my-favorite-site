# DOC https://www.rubyguides.com/2012/01/parsing-html-in-ruby/

require 'open-uri'
require 'nokogiri'

# ВЕТХИЙ ЗАВЕТ
books = {
  'gen' => {chapters: 50, name: 'Бытие'},
  'ish' => {chapters: 40, name: 'Исход'},
  'lev' => {chapters: 27, name: 'Левит'},
  'chis' => {chapters: 36, name: 'Числа'},
  'vtor' => {chapters: 34, name: 'Второзаконие'},
  'nav' => {chapters: 24, name: 'Иисус Навин'},
  'sud' => {chapters: 21, name: 'Судьи'},
  'ruf' => {chapters: 4, name: 'Руфь'},
  '1ts' => {chapters: 31, name: '1-я Царств'},
  '2ts' => {chapters: 24, name: '2-я Царств'},
  '3ts' => {chapters: 22, name: '3-я Царств'},
  '4ts' => {chapters: 25, name: '4-я Царств'},
  '1par' => {chapters: 29, name: '1-я Паралипоменон'},
  '2par' => {chapters: 36, name: '2-я Паралипоменон'},
  'ezd' => {chapters: 10, name: 'Ездра'},
  'neem' => {chapters: 13, name: 'Неемия'},
  '2ezd' => {chapters: 9, name: '2-я Ездры'},
  'tov' => {chapters: 14, name: 'Товит'},
  'iud' => {chapters: 16, name: 'Иудифь'},
  'esf' => {chapters: 10, name: 'Есфирь'},
  'pr' => {chapters: 31, name: 'Притчи'},
  'ekl' => {chapters: 12, name: 'Екклесиаст'},
  'pp' => {chapters: 8, name: 'Песня Песней'},
  'prs' => {chapters: 19, name: 'Премудрость Соломона'},
  'prsir' => {chapters: 51, name: 'Сирах'},
  'iov' => {chapters: 42, name: 'Иов'},
  'is' => {chapters: 66, name: 'Исаия'},
  'ier' => {chapters: 52, name: 'Иеремия'},
  'pier' => {chapters: 5, name: 'Плач Иеремии'},
  'pos' => {chapters: 1, name: 'Послание Иеремии'},
  'var' => {chapters: 5, name: 'Варух'},
  'iez' => {chapters: 48, name: 'Иезекииль'},
  'dan' => {chapters: 14, name: 'Даниил'},
  'os' => {chapters: 14, name: 'Осия'},
  'iol' => {chapters: 3, name: 'Иоиль'},
  'am' => {chapters: 9, name: 'Амос'},
  'av' => {chapters: 1, name: 'Авдий'},
  'ion' => {chapters: 4, name: 'Иона'},
  'mih' => {chapters: 7, name: 'Михей'},
  'naum' => {chapters: 3, name: 'Наум'},
  'avm' => {chapters: 3, name: 'Аввакум'},
  'sof' => {chapters: 3, name: 'Софония'},
  'ag' => {chapters: 2, name: 'Аггей'},
  'zah' => {chapters: 14, name: 'Захария'},
  'mal' => {chapters: 4, name: 'Малахия'},
  '1mak' => {chapters: 16, name: '1-я Маккавейская'},
  '2mak' => {chapters: 15, name: '2-я Маккавейская'},
  '3mak' => {chapters: 7, name: '3-я Маккавейская'},
  '3ezd' => {chapters: 16, name: '3-я Ездры'},
  'ps' => {chapters: 151, name: 'Псалтирь'},
}

books.each do |book_code, data|
  chapters = data[:chapters] + 2 # проверяем на всякий случай сверх нормы, вдруг промахнулись с числом
  new_book_code = book_code == 'iud' ? 'iudf' : book_code

  (1..chapters).each do |chap|
    # REQUEST
    if book_code == 'ps'
      chap = '%03d' % [ chap ]
    else
      chap = '%02d' % [ chap ]
    end

    puts " === #{book_code}:#{chap}"

    url = "http://bible.optina.ru/old:#{book_code}:#{chap}:start"
    doc = Nokogiri::HTML(URI.open(url))

    stihi = doc.css("li div.li a")

    i = 1
    stihi.each do |stih|
      # PREPARE
      text = stih.content
      is_alt = stih.classes.include?('wikilink2')

      ## VALIDATE
      # _old, _book, _chapter, _number = stih.attributes['title'].value.split(':')
      # if _book.to_s != book_code.to_s || _chapter.to_i != chap.to_i || _number.to_i != i
      #   puts "EXPECT: #{book_code.to_s}:#{chap.to_i}:#{i}"
      #   puts "GET: #{_book.to_s}:#{_chapter.to_i}:#{_number.to_i}"
      #   raise('stih validation')
      # end

      # CREATE!
      Stih.create!(
        _id: "#{new_book_code}:#{chap.to_i}:#{ i }",
        book: new_book_code,
        ch: chap.to_i,
        num: i,
        text: text,
        s: is_alt ? 2 : 1
      )

      i+=1
    end

    sleep 1
  end
end

# НОВЫЙ ЗАВЕТ
books = {
  'mf' => {chapters: 28, name: 'От Матфея'},
  'mk' => {chapters: 16, name: 'От Марка'},
  'lk' => {chapters: 24, name: 'От Луки'},
  'in' => {chapters: 21, name: 'От Иоанна'},
  'act' => {chapters: 28, name: 'Деяния'},
  'iak' => {chapters: 5, name: 'Иакова'},
  '1pet' => {chapters: 5, name: '1-е Петра'},
  '2pet' => {chapters: 3, name: '2-е Петра'},
  '1in' => {chapters: 5, name: '1-е Иоанна'},
  '2in' => {chapters: 1, name: '2-е Иоанна'},
  '3in' => {chapters: 1, name: '3-е Иоанна'},
  'iud' => {chapters: 1, name: 'Иуды'},
  'rim' => {chapters: 16, name: 'К Римлянам'},
  '1kor' => {chapters: 16, name: '1-е Коринфянам'},
  '2kor' => {chapters: 13, name: '2-е Коринфянам'},
  'gal' => {chapters: 6, name: 'К Галатам'},
  'ef' => {chapters: 6, name: 'К Ефесянам'},
  'fil' => {chapters: 4, name: 'К Филиппийцам'},
  'kol' => {chapters: 4, name: 'К Колосянам'},
  '1sol' => {chapters: 5, name: '1-е Солунянам'},
  '2sol' => {chapters: 3, name: '2-е Солунянам'},
  '1tim' => {chapters: 6, name: '1-е Тимофею'},
  '2tim' => {chapters: 4, name: '2-е Тимофею'},
  'tit' => {chapters: 3, name: 'К Титу'},
  'fm' => {chapters: 3, name: 'К Филимону'},
  'evr' => {chapters: 13, name: 'К Евреям'},
  'otkr' => {chapters: 22, name: 'Откровение'},
}


books.each do |book_code, data|
  chapters = data[:chapters] + 2 # проверяем на всякий случай сверх нормы, вдруг промахнулись с числом

  (1..chapters).each do |chap|
    # REQUEST
    chap = '%02d' % [ chap ]

    puts " === #{book_code}:#{chap}"

    url = "http://bible.optina.ru/new:#{book_code}:#{chap}:start"
    doc = Nokogiri::HTML(URI.open(url))

    stihi = doc.css("li div.li a")

    i = 1
    stihi.each do |stih|
      # PREPARE
      text = stih.content
      is_alt = stih.classes.include?('wikilink2')

      # CREATE!
      Stih.create!(
        _id: "#{book_code}:#{chap.to_i}:#{ i }",
        book: book_code,
        ch: chap.to_i,
        num: i,
        text: text,
        s: is_alt ? 2 : 1
      )

      i+=1
    end

    sleep 1
  end
end










