# Нормализация арабского текста для поиска.
#
# Арабская Библия (Ван Дейк) в базе — с огласовками (харакат), а пользователь
# печатает обычным текстом: «المسيح» не находит «ٱلْمَسِيحُ». PGroonga сравнивает
# слова как есть, поэтому для поиска храним нормализованную копию текста
# (verses.text_search_ar, page_paragraphs.content_ar) и нормализуем запрос.
module ArabicSearchNormalizer
  # огласовки (харакат), надстрочный алиф, коранические знаки, татвиль
  DIACRITICS = /[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]/
  # варианты букв, которые пользователи не различают при наборе
  LETTER_VARIANTS = {
    'أ' => 'ا', 'إ' => 'ا', 'آ' => 'ا', 'ٱ' => 'ا',
    'ى' => 'ي', 'ة' => 'ه',
  }.freeze

  # Текст без огласовок и с унифицированными буквами
  def self.normalize(text)
    text.to_s
      .gsub(DIACRITICS, '')
      .tr(LETTER_VARIANTS.keys.join, LETTER_VARIANTS.values.join)
  end

  # Подсветка совпадений в исходном тексте (с огласовками).
  # PGroonga highlight_html не находит неогласованные слова, поэтому оборачиваем
  # найденные слова сами. Возвращает HTML с <span class="keyword">.
  def self.highlight(text, keywords)
    needles = Array(keywords).map { |keyword| normalize(keyword) }.reject(&:empty?)
    return ERB::Util.html_escape(text.to_s) if needles.empty?

    text.to_s.split(/(\s+)/).map do |token|
      next token if token.match?(/\A\s+\z/)

      escaped = ERB::Util.html_escape(token)
      found = needles.any? { |needle| normalize(token).include?(needle) }
      found ? %(<span class="keyword">#{escaped}</span>) : escaped
    end.join
  end
end
