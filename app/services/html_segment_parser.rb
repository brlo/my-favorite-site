# HtmlSegmentParser.new("<h2>Test head2</h2><blockquote>My <strong>block</strong> quote</blockquote><p>paragraph</p>").parse
# =>
# [{text: "Test head2", open_tags: [{n: {n: "h2"}}], close_tags: [{n: "h2"}]},
#  {text: "My", open_tags: [{n: {n: "blockquote"}}], close_tags: []},
#  {text: "block", open_tags: [{n: {n: "strong"}}], close_tags: [{n: "strong"}]},
#  {text: "quote", open_tags: [], close_tags: [{n: "blockquote"}]},
#  {text: "paragraph", open_tags: [{n: {n: "p"}}], close_tags: [{n: "p"}]}]

#
# <strong>кроме Меня нет Бога</strong>" (<a href="/ru/is/44/#L6">Ис. 44:6</a>)</p><img src="/logo.png"></blockquote>'; HtmlSegmentParser.new(html).parse
# =>
# [{text: "“Так говорит Господь, Царь Израиля, и Искупитель его, Господь Саваоф: Я первый и Я последний, и",
#   open_tags: [{n: {n: "blockquote"}}, {n: {n: "p"}}],
#   close_tags: []},
#  {text: "кроме Меня нет Бога", open_tags: [{n: {n: "strong"}}], close_tags: [{n: "strong"}]},
#  {text: "\" (", open_tags: [], close_tags: []},
#  {text: "Ис. 44:6", open_tags: [{n: {n: "a"}, a: {href: "/ru/is/44/#L6"}}], close_tags: [{n: "a"}]},
#  {text: ")", open_tags: [], close_tags: [{n: "p"}]},
#  {text: nil, open_tags: [], close_tags: []},
#  {text: nil, open_tags: [{n: "img", a: {src: "/logo.png"}}], close_tags: [{n: "img"}, {n: "blockquote"}]}]

class HtmlSegmentParser
  SENTENCE_ENDINGS = /[.!?…。！？]/

  def initialize(html_content, lang: :ru)
    @html_content = html_content
    # @lang = lang # пока что не используется
  end

  def parse
    html_parts = split_html(@html_content)
    build_segments(html_parts)
  end

  private

  def build_segments(html_parts)
    segments = []

    open_tags = []
    close_tags = []
    current_text = nil

    html_parts.each_with_index do |part, index|
      next unless part.present?
      # prev_part = html_parts[index-1]
      # next_part = html_parts[index+1]

      # тэг открывающий
      if opening_tag?(part)
        name = tag_name(part)
        if current_text
          segments << build_segment(current_text, open_tags, close_tags)
          current_text = nil; open_tags = []; close_tags = []
        end

        tag = build_tag(name)
        if name == 'a'
          a_href = extract_href(part)
          a_tag = build_tag(name, {href: a_href})
          open_tags << a_tag
        else
          open_tags << tag
        end

      # тэг закрывающий
      elsif closing_tag?(part)
        name = tag_name(part)
        # при встрече первого закрывающего тэга в любом случае строим сегмент,
        # а если следоам потом встретяться ещё закрывающие тэги, то докинем их потом в этот последний сегмент
        if current_text
          close_tags << build_tag(name)
          segments << build_segment(current_text, open_tags, close_tags)
          current_text = nil; open_tags = []; close_tags = []
        else
          # Изначально было так:
          # segments[-1][:close_tags] << build_tag(name)
          # Но когда встречаем тэг без содержимого (служебные ссылки, например),
          # то падаем, так как пусто в segments[-1] (нет текста внутри тэга).
          # Решил просто пропускать такие пустые тэги:
          if segments[-1].nil? && open_tags.any? && open_tags.last[:n] == name
            open_tags.pop
          else
            segments[-1][:close_tags] << build_tag(name)
          end
        end

      # тэг самозакрывающийся
      elsif self_closing_tag?(part)
        name = tag_name(part)

        segments << build_segment(current_text, open_tags, close_tags)
        current_text = nil; open_tags = []; close_tags = []

        if name == 'img'
          tag = build_tag(name)
          img_src = extract_src(part)
          img_tag = build_tag(name, {src: img_src})
          segments << build_segment(nil, [img_tag], [tag])
        else
          tag = build_tag(name)
          segments << build_segment(nil, [tag], [tag])
        end

      # Текст (так как это уже ясно, что не тэги)
      else
        t_parts = split_text(part)
        t_parts.each do |t_part|
          segments << build_segment(t_part, open_tags, close_tags)
          current_text = nil; open_tags = []; close_tags = []
        end
      end
    end

    segments
  end

  def build_segment text, open_tags = [], close_tags = []
    {
      text:,
      open_tags:,
      close_tags:,
    }
  end

  def build_tag(tag_name, tag_attrs = nil)
    if tag_attrs.present?
      { n: tag_name, a: tag_attrs }
    else
      { n: tag_name }
    end
  end

  def split_html(html)
    parts = []
    i = 0
    n = html.length

    while i < n
      if html[i] == '<'
        # ТЭГ. Нашли начало тега - извлекаем весь тег
        tag_end = html.index('>', i)
        if tag_end
          parts << html[i..tag_end]
          i = tag_end + 1
        else
          # Если нет закрывающей скобки, добавляем оставшийся текст
          parts << html[i..-1]
          break
        end
      else
        # ТЕКСТ. Нашли текст - извлекаем до следующего тега или конца строки
        text_end = html.index('<', i) || n
        text = html[i...text_end]
        parts << text unless text.empty?
        i = text_end
      end
    end

    parts
  end

  # Разбиваем текст на части, удобные для перевода.
  # - максимальная часть фрагмента 200 символов.
  # - но отрезать надо либо до конца предлоения, либо до знака препинания, либо до пробела (по приоритету).
  def split_text(text, max_length: 200)
    parts = []
    start_index = 0

    while start_index < text.length
      # Ищем конец предложения в пределах максимальной длины
      search_end = [start_index + max_length, text.length].min
      chunk = text[start_index...search_end]

      # Приоритеты поиска точки разбивки
      break_index = nil

      # 1. Ищем знаки конца предложения (с учетом разных языков)
      if match = chunk.match(/[.!?…。！？]\s/)
        break_index = start_index + match.end(0) - 1
      # 2. Ищем любые знаки препинания (если текст большой)
      elsif chunk.size >= max_length && match = chunk.match(/[,:;]\s/)
        break_index = start_index + match.end(0) - 1
      # 3. Ищем пробел (если текст большой)
      elsif chunk.size >= max_length && index = chunk.rindex(' ')
        break_index = start_index + index
      # 4. Если ничего не нашли, разбиваем по максимальной длине
      else
        break_index = search_end
      end

      # Добавляем часть (убираем начальные пробелы)
      part = text[start_index...break_index].strip


      if part.present?
        if part.length < 20 && parts.last.to_s.length <= max_length
          # если часть слишком короткая, а предыдущая часть ещё не слишком большая,
          # то присоединяем эту часть к предыдущей.
          last_part = parts.pop
          parts << [last_part, part].compact.join(' ')
        else
          parts << part
        end
      end

      # Переходим к следующей части
      start_index = break_index
    end

    parts
  end


  def opening_tag?(element)
    element =~ /\A<[^\/!][^>]*>\z/ && !self_closing_tag?(element)
  end

  def closing_tag?(element)
    element =~ /\A<\/[^>]+>\z/
  end

  def self_closing_tag?(element)
    element =~ /\A<[^>]+\/>\z/ ||
    # Проверяем стандартные самозакрывающиеся теги
    element =~ /\A<(br|hr|img)[^>]*>\z/i
  end

  # def text?(element)
  #   !(opening_tag?(element) || closing_tag?(element) || self_closing_tag?(element))
  # end

  def tag_name(element)
    return nil unless element =~ /\A<\/?([^\s>]+)/
    $1.downcase
  end

  # извлекает значение href из тэга a
  def extract_href(html_string)
    html_string[/href\s*=\s*["']([^"']+)["']/, 1]
  end

  # извлекает значение src из тэга img
  def extract_src(html_string)
    html_string[/src\s*=\s*["']([^"']+)["']/, 1]
  end
end
