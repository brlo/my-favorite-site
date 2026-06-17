module TranslationHelper
  # Рендерит текст сегмента с учётом open_tags / close_tags
  def render_segment_html(segment)
    return segment.text.to_s.html_safe unless segment.text.present?

    html = segment.text
    segment.open_tags.each { |tag| html = wrap_tag(html, tag) }
    segment.close_tags.reverse.each { |tag| html += close_tag(tag) }
    html.html_safe
  end

  def language_name(code)
    {
      'ru' => 'русский',
      'en' => 'English',
      'de' => 'Deutsch',
      'la' => 'Latina',
      'grc' => 'Ἑλληνική'
    }[code] || code
  end

  private

  def wrap_tag(content, tag)
    return content unless tag.is_a?(Hash) && tag[:n]
    attrs = tag[:a]&.map { |k, v| %(#{k}="#{v}") }&.join(' ')
    "<#{tag[:n]}#{attrs.present? ? " #{attrs}" : ''}>#{content}"
  end

  def close_tag(tag)
    return '' unless tag.is_a?(Hash) && tag[:n]
    "</#{tag[:n]}>"
  end

  def langs_for_translates
    ::PAGE_LANGS.reject { |k,v| v.nil? }
  end
end
