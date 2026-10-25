module DictWordsHelper
  # Статья словаря для страницы слова. В статьях STEPBible ссылки на Библию хранятся без языка (/mf/16#L18) -
  # ведём их сразу на перевод, который сейчас читает пользователь.
  def dict_word_desc_html(dict_word)
    html = sanitize(dict_word.desc.to_s, tags: ::DictWord::ALLOW_TAGS, attributes: ::DictWord::ALLOW_ATTRS)
    return html unless dict_word.dict.in?(::DictWord::STEP_DICTS)

    html.gsub(%r{href="(/[^"/]+/\d+[^"]*)"}) { "href=\"#{my_bib_link_to(::Regexp.last_match(1))}\"" }.html_safe
  end

  # Греческий стих и его перевод с подсвеченным словом. Вхождения ищем в разметке подстрочника (data['wi']):
  # match отбирает слова (по bw_id или по лексеме), их перевод в этом стихе (trl) подсвечиваем в переводе.
  # greek_fallback - формы для подсветки, если у стиха ещё нет подстрочника.
  #   greek_re, translated_re = verse_pair_highlights(greek, translated, greek_fallback: [bw.word]) { |wi| wi["bw_id"] == bw.id }
  def verse_pair_highlights(greek, translated, greek_fallback: [], &match)
    hits = greek&.data.to_h['wi'].to_a.select(&match)
    greek_words = hits.filter_map { _1['w'] }.presence || greek_fallback
    glosses = translated ? hits.filter_map { _1.dig('trl', translated.lang) } : []

    [greek_words.uniq.map { whole_word_regexp(_1) }, glosses.uniq.flat_map { gloss_regexps(_1, translated.lang) }]
  end

  private

  def whole_word_regexp(word)
    /(?<!\p{L})#{case_free(word.unicode_normalize(:nfc))}(?!\p{L})/
  end

  # Заглавная или строчная первая буква (начало предложения). Флаг /i не годится:
  # в Onigmo (?<!\p{L}) с /i не находит греческие буквы с ударением ("λόγον").
  def case_free(word)
    first = word[0].to_s
    head = first.downcase == first.upcase ? ::Regexp.escape(first) : "[#{first.downcase}#{first.upcase}]"
    head + ::Regexp.escape(word[1..].to_s)
  end

  # Перевод в подстрочнике стоит в начальной форме, а в тексте перевода слово склоняется:
  # "темницу" ищем как "темниц…", короткие слова ("и", "в") - только целиком. В японском границ слов нет:
  # ищем подстроку без окончания-хираганы.
  def gloss_regexps(gloss, lang)
    gloss = gloss.unicode_normalize(:nfc)
    if lang == 'ja'
      stem = gloss.sub(/\p{Hiragana}+\z/, '')
      return stem.empty? ? [] : [/#{::Regexp.escape(stem)}/]
    end

    words = gloss.scan(/\p{L}+/)
    words = words.select { _1.length > 3 } if words.size > 1 # в "в темницу" предлог не подсвечиваем
    words.map do |w|
      next whole_word_regexp(w) if w.length <= 3

      stem = w[0...(w.length > 5 ? -2 : -1)]
      /(?<!\p{L})#{case_free(stem)}\p{L}*/
    end
  end
end
