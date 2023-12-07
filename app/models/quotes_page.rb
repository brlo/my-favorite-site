require 'nokogiri'
# QuotesPage.create_indexes

class QuotesPage
  include Mongoid::Document

  # название
  field :title, type: String
  # meta-описание (через запятую ключевые слова)
  field :meta_desc, type: String
  # путь в url
  field :path, type: String
  # язык
  field :lang, type: String
  # текст статьи
  field :body, type: String
  # ссылки на использованные стихи
  field :addresses, type: Array
  # id темы
  field :s_id, as: :subject_id, type: String
  # место в списке (1 - первое, и тд)
  field :position, type: Integer
  # время создания можно получать из _id во так: id.generation_time
  field :c_at, as: :created_at, type: DateTime, default: ->{ DateTime.now.utc.round }

  # rake db:mongoid:create_indexes
  # rake db:mongoid:remove_indexes
  # rake db:mongoid:remove_undefined_indexes
  # для поиска в нужной книге
  index({s_id: 1}, {background: true})

  before_validation :normalize_attributes
  before_validation :grab_quote_addresses
  before_validation :redefine_html_links
  validates :title, :lang, :s_id, presence: true

  # находим и сохраняем цитаты из текста в спец. поле: addresses
  # находит в тексте статьи цитаты в скобках, возвращает массив без скобок:
  # [
  #   "Деян. 14:15",
  #   "/act/14/#L15"
  # ],
  # [
  #   "Исх. 20:11",
  #   "/ish/20/#L11"
  # ]
  def grab_quote_addresses
    # TIP: нужно избавляться от всех html-тэгов, иначе не все ссылки находит
    # TIP: если в sanitizer не передавать tags, то он не все тэги удалит (а надо все удалить)
    body_without_html = sanitizer.sanitize(self.body.to_s, tags: [])

    # старый универсальный способ находить ссылки в скобках:
    # \b - границы слова.
    # \d{0,1}i{0,3}[ \s] - какая-то цифра (арабская или римская), а потом пробел.
    # [[:alnum:]]{0,20}\.{0,1}[ \s]{0,2} - название книги, возможно с сокращением и пробелом.
    # \d{1,3} - номер главы.
    # :{0,1}[\-,\d]{0,30} - какие-то стихи через запятую или тире.
    # \b - граница слова
    # regex = /\b(\d{0,1}i{0,3}[ \s]{0,1}[[:alnum:]]{0,20}\.{0,1}([ \s]{0,2}\d{1,3}:{0,1}[\-,\d]{0,25})+)\b/i

    # Match result:
    # (Мф. 123:1-15,  1:12;  12:13-1; 12:14-1)
    #
    # Match groups:
    # 1.	Мф.                       - 1 группа - название книги
    # 2.	123:1-15                  - 2 группа - первый обязательный адрес
    # 3.	, 1:12; 12:13-1; 12:14-1  - 3 группа - вся оставшаяся пачка дополнительных адресов без названия книги
    # 4.	; 12:14-1                 - 4 группа не нужна (это последний необязательный адрес)
    regex = /\b(\d{0,1}i{0,3}[ \s]{0,1}[a-zа-я]{1,20}\.{0,1}[ \s]{0,3})(\d{1,3}:{0,1}[\d\-\,]{0,15}){1}(([\,\;]{1}[ \s]{1,3}\d{1,3}\:{1}[\-\,\d]{1,15}){0,15})\b/i
    # вариант без дополнительных ссылок (можно просто переключиться и всё заработает, а доп. ссылки просто не выделятся никак)
    # regex = /\b(\d{0,1}i{0,3}[ \s]{0,1}[a-zа-я]{1,20}\.{0,1}[ \s]{0,3})(\d{1,3}:{0,1}[\d\-\,]{0,15}){1}\b/i

    # TIP: СНОВА ВЕРНУЛИСЬ К СТАРОМУ СПОСОБУ КАК К БОЛЕЕ УНИВЕРСАЛЬНОМУ, А ДАЛЕЕ ПРОСТО ПРОВЕРЯЕМ НАЗВАНИЕ КНИГИ
    # новый способ находить ссылки без скобок, в том числе и много ссылок через запятую
    # regex = /([1-4\-аяое\s]*(Быт|Исх|Лев|Чис|Втор|Нав|Суд|Руф|Цар|Пар|Ездр|Неем|Тов|Иудифь|Есф|Притч|Еккл|Песн|Прем|Сир|Иов|Ис|Иер|Плач|Посл\.Иер|Вар|Иез|Дан|Ос|Иоиль|Ам|Авд|Иона|Мих|Наум|Авв|Соф|Агг|Зах|Мал|Макк|Пс|Мф|Мк|Лк|Ин|Деян|Иак|Пет|Ин|Иуд|Рим|Кор|Гал|Еф|Флп|Кол|Сол|Фес|Тим|Тит|Флм|Евр|Откр|Бытие|Исход|Левит|Числа|Второзаконие|Иисус Навин|Судьи|Руфь|Царств|Паралипоменон|Ездра|Неемия|Ездры|Товит|Иудифь|Есфирь|Притчи|Екклесиаст|Песня Песней|Премудрости Соломона|Сирах|Иов|Исаия|Иеремия|Плач Иеремии|Послание Иеремии|Варух|Иезекииль|Даниил|Осия|Иоиль|Амос|Авдий|Иона|Михей|Наум|Аввакум|Софония|Аггей|Захария|Малахия|Маккавейская|Псалтирь|Матфея|Марка|Луки|Иоанна|Деяния|Деяния апостолов|Иакова|Петра|Иоанна|Иуды|Римлянам|Коринфянам|Галатам|Ефесянам|Филиппийцам|Колосянам|Солунянам|Фессалоникийцам|Тимофею|Титу|Филимону|Евреям|Откровение|Gen|Ex|Lev|Num|Deut|Nav|Judg|Rth|Sam|King|Chron|Ezr|Nehem|Tov|Judf|Est|Prov|Eccl|Song|Solom|Sir|Job|Is|Jer|Lam|lJer|Bar|Ezek|Dan|Hos|Joel|Am|Avd|Jona|Mic|Naum|Habak|Sofon|Hag|Zah|Mal|Mac|Ps|Mt|Mk|Lk|Jn|Act|Jas|Pet|Jn|Juda|Rom|Cor|Gal|Eph|Phil|Col|Thes|Tim|Tit|Phlm|Hebr|Rev|Genesis|Exodus|Leviticus|Numbers|Deuteronomy|Joshua|Judges|Ruth|Samuel|Kings|Chronicles|Esdras|Nehemiah|Tobit|Judith|Esther|Proverbs|Ecclesiastes|Song of Solomon|Wisdom|Sirah|Job|Isaiah|Jeremiah|Lamentations|Letter of Jeremiah|Baruch|Ezekiel|Daniel|Hosea|Joel|Amos|Obadiah|Jonah|Micah|Nahum|Habakkuk|Zephaniah|Haggai|Zachariah|Malachi|Maccabees|Psalms|Matthew|Mark|Luke|John|Acts|James|Peter|John|Jude|Romans|Corinthians|Galatians|Ephesians|Philippians|Сolossians|Thessalonians|Timothy|Titus|Philemon|Hebrews|Revelation)\.*[ \s]*\d{1,3}:*[\d\,\-]{0,20})[,;]*/i

    # сюда положим то, что похоже на ссылку
    maybe_matches = []
    body_without_html.scan(regex).each do |match|
      # см. описание regexp выше
      book_name, main_address, rest_addresses = match
      # , 1:12; 12:13-1; 12:14-1 — приводим в порядок, оставляя только адреса
      rest_addresses = rest_addresses.to_s.split(/[,;][ \s]/).reject(&:empty?)
      #                 имя книги, главный адрес, массив дополнительных адресов
      maybe_matches << [book_name, main_address, rest_addresses]
    end

    # сюда положим то, что точно является ссылками (проверили название книги)
    matches = []
    maybe_matches.each do |book_name, main_address, rest_addresses|
      # сначала пробуем главный адрес с названием книги
      q_human = "#{book_name}#{main_address}"
      href = ::AddressConverter.human_to_link(q_human)
      matches << [q_human, href] if href

      # затем пробуем все дополнительные адреса, но запоминаем просто адрес, без книги
      # TIP: может быть проблема, если в тексте будет два одинаковых дополнительых адреса к
      # разным книгам: 1:6 и 1:6, но они шли к разным книгам, а мы записилим сначала обоим
      # одну ссылку, а потом обоим же — другую.
      rest_addresses.each do |address|
        q_human = "#{book_name}#{address}"
        href = ::AddressConverter.human_to_link(q_human)
        matches << [address, href] if href
      end
    end

    self.addresses = matches
  end

  # пересоздаём ссылки на библейские стихи (вдруг, они кривые или ведут на другие сайты)
  def redefine_html_links
    # удаляем имеющиеся ссылки на стихи (они могут быть неправильными, а мы пересоздадим)
    doc = ::Nokogiri.HTML(self.body.to_s)
    doc.css('a').each do |el|
      html_link_to_addr = ::AddressConverter.human_to_link(el.text)
      # меняем на текст, избавлясь от html-тэга, если:
      # - у ссылки нет текста или поняли
      # - это ссылка на библейский стих
      # - это доп. ссылка типа: 15:1
      if el.text.blank? || html_link_to_addr || el.text =~ /\d{1,3}:{1}[\d\-\,]{1,15}/
        # el.replace(el.inner_html)
        el.replace(el.text)
      end
    end

    # Далее собираемся менять библейские адреса на html-ссылки
    # но не всё подряд, а по порядку:
    # - берём певую ссылку и отсекаем часть текста до неё (first_part)
    # - берём саму ссылку (occur) и заменяем на html-ссылку
    # - а в оставшемся тексте (last_part) будем точно также искать следующую ссылку.
    #
    # Таким образом, не испортим уже поменянные ссылки вроде Быт. 16:11 на Быт. 16:1
    # А так же, сможем заменить доп. ссылки типа 16:1 (без книги),
    # которые идут сразу после нормальных ссылок в качестве дополнения.
    new_text = ""
    last_part = doc.to_html

    # добавляем ссылки заново
    # TIP: у нас уже есть заранее найденные адреса и гиперссылки на них.
    # Просто пройдёмся по тексту и поменяем текст на текст со сылкой
    self.addresses.each do |q_human, href|
      next if q_human.blank?
      next if href.blank?

      # создаём новый элемент-ссылку
      new_node = doc.create_element('a')
      # заполняем href ссылки
      new_node['href'] = "/#{self.lang}" + href
      # заполняем текст ссылки
      new_node.inner_html = q_human
      # разбиваем текст на части по ближайшему совпадению
      first_part, occur, last_part = last_part.partition(q_human)
      # часть "ДО совпадения" отправляем сразу в окончательный текст
      # совпадение делам ссылкой, и отправляем в следующую итерацию цикла
      new_text += first_part + new_node.to_html
    end

    # после цикла надо докинуть остаток в результат
    new_text += last_part

    self.body = new_text
  end

  def normalize_attributes
    self.title = self.title.to_s.strip
    self.meta_desc = self.meta_desc.to_s.strip
    self.path = self.path.to_s.strip
    self.lang = self.lang.to_s.strip
    self.body = self.body.to_s.strip

    # избавяемся от лишних в тэгов
    self.body = sanitizer.sanitize(
      self.body,
      tags: %w(div ul ol li h1 h2 h3 blockquote b i em strike s u hr br a mark img code)
    )

    # Заменяем неразрывные пробелы (&nbsp;) на обычные. Иначе строки не рвутся, выглядит очень странно
    # приходят эти пробелы, походу, через редактор Pell. В базе выглядит уже не как &nbsp;, а как обычный пробел,
    # поэтому сразу и не распознаешь, а вот в VSCode он выделяется жёлтым прямоугольником.
    self.body = self.body.gsub(' ', ' ')
    self.body = self.body.gsub('&nbsp;', ' ')

    # если позиция не задана, ставим сами максимальную+1
    if self.position.blank?
      self.position = ::QuotesPage.where(:position.nin => [nil, '']).order(position: :asc).last&.position.to_i + 1
    end
  end

  private

  def sanitizer
    @sanitizer ||= ::Rails::Html::SafeListSanitizer.new
  end
end

# i=10;QuotesPage.each{|s| s.update!(position: i); i+=10; }

# qs = QuotesSubject.create!(name_ru: 'Бог', name_en: 'God', p_id: nil)
# QuotesSubject.create!(name_ru: 'Бог один', name_en: 'God is one', p_id: qs._id.to_s)
# QuotesSubject.create!(name_ru: 'Бог троичен', name_en: 'Trinity', p_id: qs._id.to_s)
# QuotesSubject.create!(name_ru: 'Бог свойства', name_en: 'Trinity', p_id: qs._id.to_s)
# QuotesSubject.create!(name_ru: 'Бог титулы', name_en: 'Trinity', p_id: qs._id.to_s)
# QuotesSubject.create!(name_ru: 'Бог характер', name_en: 'Trinity', p_id: qs._id.to_s)

# qs = QuotesSubject.create!(name_ru: 'Христос', name_en: 'Christ', p_id: nil)
# QuotesSubject.create!(name_ru: 'Христос — Бог', name_en: 'Christ is God', p_id: qs._id.to_s)

# qs = QuotesSubject.create!(name_ru: 'Церковь', name_en: 'Christ', p_id: nil)
# qs = QuotesSubject.create!(name_ru: 'Спасение', name_en: 'Christ', p_id: nil)

