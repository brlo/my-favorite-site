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

  # [[lang_code, name], ...]
  def langs_for_translates(is_with_encient: true)
    ::TRANSLATE_LANGS.map do |lang_code, params|
      next if params[:is_encient] == true && is_with_encient != true

      name = translation_lang_by_code(lang_code)
      # значение для select
      value = lang_code
      [value, name]
    end.compact
  end

  # Название языка (все названия не переведены, название языка приводится на этом же языке,
  # но названия древних языков nil, в этом случае мы покажем название древнего языка на языке интерфейса)
  def translation_lang_by_code(lang_code)
    lang_params = ::TRANSLATE_LANGS[lang_code]

    return if lang_params.nil?

    lang_name = lang_params[:name] || I18n.t("page_translations.#{lang_code}")
    "#{lang_params[:flag]} #{lang_name}"
  end

  def percent_color percents
    return '#22c55e' if percents >= 80
    return '#eab308' if percents >= 50
    return '#f97316' if percents >= 20
    '#ef4444'
  end
end
