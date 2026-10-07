require 'nokogiri'
require_relative '../../../lib/tools/string_utils/rubyfy'

# Превращает HTML, написанный редактором, в то, что показываем читателю:
# чистит теги, строит оглавление, ссылки на сноски, источники под цитатами и т.п.
# Не знает ничего про Page и БД — только строки на входе и на выходе.
module Page::HtmlRenderer
  # Результат render_body
  #   body     - очищенный HTML для редактора (сноски обычным текстом)
  #   rendered - HTML для читателя
  #   menu     - оглавление [[тег, якорь, текст], ...]
  Body = Struct.new(:body, :rendered, :menu, keyword_init: true)

  module_function

  # Разрешённые теги и атрибуты, лишние пробелы и пустые параграфы убираем
  def safe_html(html_text)
    # Заменяем неразрывные пробелы (&nbsp;) на обычные. Иначе строки не рвутся, выглядит очень странно
    # приходят эти пробелы, походу, через редактор Pell. В базе выглядит уже не как &nbsp;, а как обычный пробел,
    # поэтому сразу и не распознаешь, а вот в VSCode он выделяется жёлтым прямоугольником.

    # tiptap в пустой строке внутрь <p></p> засовывает вот этот странный br:
    html_text = html_text.to_s.gsub('<br class="ProseMirror-trailingBreak">', '')
    html_text = html_text.to_s.gsub('<p></p>', '')
    html_text = html_text.to_s.gsub("\u00A0", ' ')
    html_text = html_text.to_s.gsub('&nbsp;', ' ')

    # избавяемся от лишних тэгов, аттрибут и пустых строк
    ::Page.sanitizer.sanitize(
      html_text,
      tags: ::Page::ALLOW_TAGS,
      attributes: ::Page::ALLOW_ATTRS,
    ).gsub('<p></p>', '')
  end

  # Основной текст статьи: очистка, сноски, оглавление, источники, lazy-картинки, фуригана
  def render_body(html)
    # u00AD — это SOFT HYPHEN, с которым я намучался целый день, прежде чем понял из-за чего разбиваются целые слова
    # при нормализации в лексемы, и потом в итоге не ищутся нормально. Надо эти переносы удалять обязательно. Они часто встречаются и их не видно визуально.
    body = safe_html(html).strip.gsub("­", '')
    # body мы будем редактировать в админке, а отображать для клиента body_rendered,
    # поэтому чтоб в админке не мешать админку, мы сноски не будем ему показыват как ссылки,
    # сделаем их обычным текстом:
    body = remove_footnote_links(body)

    # построение перекрестных ссылок на сноски
    rendered = footnote_anchors(body)
    # построение оглавления и необходимых ссылок
    rendered, menu = menu_and_anchors(rendered)
    # найти источники под цитатами
    rendered = mark_quote_sources(rendered)
    # добавляем картинкам параметр отложенной загрузки: loading='lazy'
    rendered = lazy_images(rendered)
    # Add furigana: "私[わたし]" => "<ruby><rb>私</rb><rt>わたし</rt></ruby>"
    rendered = ::Tools::StringUtils::Rubyfy.call(rendered)

    Body.new(body: body, rendered: rendered, menu: menu)
  end

  # Примечания внизу статьи: (html для редактора, html для читателя)
  def render_references(html)
    references = safe_html(html).strip
    rendered = ::Tools::StringUtils::Rubyfy.call(references_back_links(references))
    [references, rendered]
  end

  # Строим из текста меню, заголовки делаем якорями. Возвращает [html, меню]
  def menu_and_anchors(text)
    doc = ::Nokogiri.HTML(text.to_s)

    # счётчик индексов для повторяющихся заголовков
    counters = Hash.new(0)

    menu = []
    doc.css('h2, h3, h4').each do |el|
      # Удаляем теги strong из текста перед обработкой
      el.css('strong').each { |e| e.replace(e.content) }
      # из текста удаляем всё, кроме букв, цифр, пробела и "-". Меняем " " на "-"
      title = el.text.gsub(/[^[[:alnum:]]\s\-]/, '').gsub(' ', '-')
      # добываем порядковый номер повторяющегося заголовка
      idx = (counters[title] += 1)
      # если такой заголовок встречается первый раз - номер не указываем
      idx = nil if idx == 1
      anchor = "HH#{idx}-#{title}"
      el['id'] = anchor
      el['name'] = anchor

      menu.push([el.name, anchor, el.text])
    end

    [inner_body(doc), menu]
  end

  # ищем сноски вида [1] в тексте, делаем якоря
  def footnote_anchors(text)
    # Для поисков нельзя допускать, чтобы в документе были элементы с одинаковым id,
    # поэтому для повторяющихся сносок, добавляем индекс, чтобы id отличались.
    indexes = Hash.new(0)

    # Цифра в квадратных скобках: [1]
    text.to_s.gsub(/(\[)(\d+)(\])/i) do
      open, number, close = $1, $2, $3
      # который раз встречается номер такой сноски? Если первая, индекс к id не добавляем
      i = (indexes[number] += 1)
      suffix = (i == 1) ? '' : "-#{i}"
      "<sup class='foot-ref'><a id='cite_ref-#{number}#{suffix}' href='#cite_note-#{number}'>#{open}#{number}#{close}</a></sup>"
    end
  end

  # Находим источники под цитатами: под blockquote параграфы, в которых на первом месте
  # стоят три элемента: "(", ссылка, ")" — такому параграфу добавляем класс source-link
  def mark_quote_sources(text)
    doc = ::Nokogiri.HTML(text.to_s)

    doc.css('blockquote + p').each do |par|
      is_ch1_ok = par.children[0]&.text? && par.children[0].text.strip == '('
      is_ch2_ok = par.children[1]&.name == 'a'
      is_ch3_ok = par.children[2]&.text? && par.children[2].text.strip[0] == ')'

      par['class'] = 'source-link' if is_ch1_ok && is_ch2_ok && is_ch3_ok
    end

    inner_body(doc)
  end

  # Обратные ссылки из примечаний к прежнему месту в тексте (продолжение footnote_anchors)
  def references_back_links(text)
    return '' if text.to_s.blank?

    doc = ::Nokogiri.HTML(text.to_s)

    ol = doc.css('ol').first
    if ol
      # указано начальная цифра списка?
      i = ol['start'].present? ? ol['start'].to_i : 1
      ol.css('li').each do |li|
        par = li.css('p').first
        if par
          # в начале каждого элемента ставим символ-ссылку для возвращения назад
          par['id'] = "cite_note-#{i}"
          par.inner_html = "<a class='foot-note' href='#cite_ref-#{i}'>↑ </a>" + par.inner_html
        end
        i += 1
      end
    end

    inner_body(doc)
  end

  # Сноски-ссылки превращаем в обычный текст
  def remove_footnote_links(text)
    return '' if text.to_s.blank?

    doc = ::Nokogiri.HTML(text.to_s)
    doc.css("a[href^='#cite_note']").each { |l| l.replace(l.content) }
    inner_body(doc)
  end

  # "<img src='a'>" -> "<img src='a' loading='lazy'>"
  def lazy_images(html)
    doc = ::Nokogiri.HTML(html)
    doc.css('img').each { |img| img['loading'] ||= 'lazy' }
    inner_body(doc)
  end

  # nokogiri добавляет html, body, которые нам не нужны
  def inner_body(doc)
    doc.at_css('body').inner_html.gsub("\n", "")
  end
end
