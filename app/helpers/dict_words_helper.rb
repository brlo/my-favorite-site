module DictWordsHelper
  # Статья словаря для страницы слова. В статьях STEPBible ссылки на Библию хранятся без языка (/mf/16#L18) -
  # ведём их сразу на перевод, который сейчас читает пользователь.
  def dict_word_desc_html(dict_word)
    html = sanitize(dict_word.desc.to_s, tags: ::DictWord::ALLOW_TAGS, attributes: ::DictWord::ALLOW_ATTRS)
    return html unless dict_word.dict.in?(::DictWord::STEP_DICTS)

    html.gsub(%r{href="(/[^"/]+/\d+[^"]*)"}) { "href=\"#{my_bib_link_to(::Regexp.last_match(1))}\"" }.html_safe
  end
end
