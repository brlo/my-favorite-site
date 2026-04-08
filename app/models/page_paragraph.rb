class PageParagraph < ApplicationRecord
  belongs_to :page
  belongs_to :page_for_preview, -> {
      select(:id, :h_id, :title, :path, :cover, :parent_id)
  }, class_name: 'Page', optional: true, foreign_key: :page_id

  before_save :normalize_attributes
  after_save :update_tsvector

  private

  def normalize_attributes
    # заменяем тэги <p> и <h1,2,3> <blockquote> на пробел (иначе слова сливаются на этих тэгах, если тэги просто убрать)
    simple_text = self.content.to_s.gsub(/<\/(?:[hH][1-9]|p|blockquote)>/, ' ')
    # убираем все диакритические знаки и ударения из греческого
    # simple_text = DictWord.word_clean_gr(simple_text.to_s) if self.lang.in?(['grc', 'el'])
    # убираем из получившихся строк все html-тэги
    self.content = sanitizer.sanitize(simple_text.to_s, tags: [])
    # clean_text = ActionView::Base.full_sanitizer.sanitize(clean_text)
  end

  def update_tsvector
    pg_dict = LANG_TO_PG_LANGUAGE[lang&.downcase]

    self.class.where(id: id).update_all(
      self.class.sanitize_sql([
        'content_tsvector = to_tsvector(?, ?)',
        pg_dict,
        self.content
      ])
    )
    # update_all - чтобы избежать повторных колбэков
  end
end
