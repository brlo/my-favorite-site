module ApplicationHelper
  def current_lang
    lang = cookies[:'b-lang']

    if ['ru', 'csl-pnm', 'csl-ru'].include?(lang)
      lang
    else
      'ru'
    end
  end

  def verse_alone_clean text
    if text[-1] =~ /[\.\,\-\;\:]/
      text[0..-2]
    else
      text
    end
  end
end
