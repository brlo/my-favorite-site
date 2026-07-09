class Verse < ApplicationRecord
  self.table_name = 'verses'

  validates :lang, :address, :book_id, :book, :chapter, :line, :text, presence: true

  before_validation :set_address_if_nil
  before_validation :normalize_attributes

  after_save :update_text_tsvector

  private

  def normalize_attributes
    # в поле text_search не должно быть html-тэгов, так как оно нужно для подсветки
    # совпадений после поиска через поле с токенами text_tsvector и показа в поисковой выдаче)
    #
    # u00AD — это SOFT HYPHEN, с которым я намучался целый день, прежде чем понял из-за чего разбиваются целые слова
    # при нормализации в лексемы, и потом в итоге не ищутся нормально. Надо эти переносы удалять обязательно. Они часто встречаются и их не видно визуально.
    self.text_search = sanitizer.sanitize(self.text, tags: []).gsub("\u00AD", '')
    self.text_search = self.text_search.gsub(/\[([\p{Hiragana}\p{Katakana}]+)\]/, '')

    # "私[わたし]" => "<ruby><rb>私</rb><rt>わたし</rt></ruby>"
    # self.text = ::Tools::StringUtils::Rubyfy.call(self.body_rendered)
  end

  def set_address_if_nil
    return unless address.blank?
    if book.present? && chapter.present? && line.present?
      self.address = "#{book}:#{chapter}:#{line}"
    else
      raise ArgumentError, 'Verse must contain Book, Chapter and Line'
    end
  end

  # Заполняем поле для поиска по тексту статьи (там должден остаться только текст, без тэгов)
  #
  # вручную запустить так:
  # # sanitizer=::Rails::Html::SafeListSanitizer.new; Verse.each {|p| p.text_search = sanitizer.sanitize(p.text.to_s.gsub(/<\/(h|p)[0-9]?>/, '.'), tags: []).split(/\s?\.+\s?/); p.save }
  def update_text_tsvector
    pg_dict = LANG_TO_PG_LANGUAGE[lang&.downcase]

    self.class.where(id: id).update_all(
      self.class.sanitize_sql([
        "text_tsvector = to_tsvector(?, ?)",
        pg_dict,
        self.text_search
      ])
    )
    # update_all - чтобы избежать повторных колбэков
  end
end
