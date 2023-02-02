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
    # старый универсальный способ находить ссылки в скобках
    regex = /\b(\d{0,1}i{0,3}[[:alnum:]]*\.*[ \s]*\d{1,3}:*\d{0,3}[ \s\-,]*\d{0,3})\b/i

    # TIP: СНОВА ВЕРНУЛИСЬ К СТАРОМУ СПОСОБУ КАК К БОЛЕЕ УНИВЕРСАЛЬНОМУ, А ДАЛЕЕ ПРОСТО ПРОВЕРЯЕМ НАЗВАНИЕ КНИГИ
    # новый способ находить ссылки без скобок, в том числе и много ссылок через запятую
    # regex = /([1-4\-аяое\s]*(Быт|Исх|Лев|Чис|Втор|Нав|Суд|Руф|Цар|Пар|Ездр|Неем|Тов|Иудифь|Есф|Притч|Еккл|Песн|Прем|Сир|Иов|Ис|Иер|Плач|Посл\.Иер|Вар|Иез|Дан|Ос|Иоиль|Ам|Авд|Иона|Мих|Наум|Авв|Соф|Агг|Зах|Мал|Макк|Пс|Мф|Мк|Лк|Ин|Деян|Иак|Пет|Ин|Иуд|Рим|Кор|Гал|Еф|Флп|Кол|Сол|Фес|Тим|Тит|Флм|Евр|Откр|Бытие|Исход|Левит|Числа|Второзаконие|Иисус Навин|Судьи|Руфь|Царств|Паралипоменон|Ездра|Неемия|Ездры|Товит|Иудифь|Есфирь|Притчи|Екклесиаст|Песня Песней|Премудрости Соломона|Сирах|Иов|Исаия|Иеремия|Плач Иеремии|Послание Иеремии|Варух|Иезекииль|Даниил|Осия|Иоиль|Амос|Авдий|Иона|Михей|Наум|Аввакум|Софония|Аггей|Захария|Малахия|Маккавейская|Псалтирь|Матфея|Марка|Луки|Иоанна|Деяния|Деяния апостолов|Иакова|Петра|Иоанна|Иуды|Римлянам|Коринфянам|Галатам|Ефесянам|Филиппийцам|Колосянам|Солунянам|Фессалоникийцам|Тимофею|Титу|Филимону|Евреям|Откровение|Gen|Ex|Lev|Num|Deut|Nav|Judg|Rth|Sam|King|Chron|Ezr|Nehem|Tov|Judf|Est|Prov|Eccl|Song|Solom|Sir|Job|Is|Jer|Lam|lJer|Bar|Ezek|Dan|Hos|Joel|Am|Avd|Jona|Mic|Naum|Habak|Sofon|Hag|Zah|Mal|Mac|Ps|Mt|Mk|Lk|Jn|Act|Jas|Pet|Jn|Juda|Rom|Cor|Gal|Eph|Phil|Col|Thes|Tim|Tit|Phlm|Hebr|Rev|Genesis|Exodus|Leviticus|Numbers|Deuteronomy|Joshua|Judges|Ruth|Samuel|Kings|Chronicles|Esdras|Nehemiah|Tobit|Judith|Esther|Proverbs|Ecclesiastes|Song of Solomon|Wisdom|Sirah|Job|Isaiah|Jeremiah|Lamentations|Letter of Jeremiah|Baruch|Ezekiel|Daniel|Hosea|Joel|Amos|Obadiah|Jonah|Micah|Nahum|Habakkuk|Zephaniah|Haggai|Zachariah|Malachi|Maccabees|Psalms|Matthew|Mark|Luke|John|Acts|James|Peter|John|Jude|Romans|Corinthians|Galatians|Ephesians|Philippians|Сolossians|Thessalonians|Timothy|Titus|Philemon|Hebrews|Revelation)\.*[ \s]*\d{1,3}:*[\d\,\-]{0,20})[,;]*/i

    # Возможные совпадения. Regex не очень точный.
    # Далее проверяем название книги из списка, и если книга неизвестна, то адресом не считаем
    # TIP: нужно избавляться от всех html-тэгов, иначе не все ссылки находит
    # TIP: если в sanitizer не передавать tags, то он не все тэги удалит (а надо все удалить)
    maybe_matches = sanitizer.sanitize(self.body.to_s, tags: []).scan(regex).map{ |s| s.first.gsub(/[()]/, '') }.uniq

    matches = []
    maybe_matches.each do |q_human|
      href = ::AddressConverter.human_to_link(q_human)
      matches << [q_human, href] if href
    end

    self.addresses = matches
  end

  # пересоздаём ссылки на библейские стихи (вдруг, они кривые или ведут на другие сайты)
  def redefine_html_links
    # удаляем имеющиеся ссылки на стихи (они могут быть неправильными, а мы пересоздадим)
    doc = ::Nokogiri.HTML(self.body.to_s)
    doc.css('a').each do |el|
      html_link_to_addr = ::AddressConverter.human_to_link(el.text)
      # если у ссылки нет текста или поняли,
      # что это ссылка на библейский стих, то меняем на текст, избавлясь от html-тэга
      if el.text.blank? || html_link_to_addr
        # el.replace(el.inner_html)
        el.replace(el.text)
      end
    end

    cleaned = doc.to_html

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
      # заменяем все подобные адреса в документе на ссылку
      cleaned.gsub!(q_human, new_node.to_html)
    end

    self.body = cleaned
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
      tags: %w(div ul ol li h1 h2 blockquote b i strike u hr br a)
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

