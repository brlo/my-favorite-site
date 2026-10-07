# Абзацы страницы для полнотекстового поиска (page_paragraphs).
# Пересобираются при изменении текста и при публикации/снятии с публикации.
module Page::Paragraphs
  extend ActiveSupport::Concern

  CHUNK_SIZE = 250

  included do
    has_many :page_paragraphs, dependent: :destroy

    before_save :cache_before_save_state
    after_save :sync_paragraphs, if: :paragraphs_stale?
  end

  private

  def cache_before_save_state
    @is_body_rendered_changed = self.body_rendered_changed?
  end

  def paragraphs_stale?
    @is_body_rendered_changed || saved_change_to_is_published? || saved_change_to_is_deleted?
  end

  def sync_paragraphs
    if is_deleted? || !is_published?
      page_paragraphs.destroy_all
      return
    end

    page_paragraphs.destroy_all
    paragraph_chunks.each_with_index do |content, idx|
      page_paragraphs.create!(position: idx, content: content, lang: lang)
    end
  end

  # Разбиваем на параграфы, заголовки и цитаты, склеиваем, пока не наберётся CHUNK_SIZE символов
  def paragraph_chunks
    parts = body.to_s.split(/<\s*\/?\s*(?:h[2-4]|p|blockquote)\b[^>]*>/i).map(&:strip).select { _1.to_s.length > 10 }

    chunks = []
    buffer = ''

    parts.each do |part|
      # Считаем длину ДО добавления
      if buffer.length + part.length > CHUNK_SIZE
        chunks << buffer if buffer.present?
        buffer = part # Длинный кусок пойдёт в новый блок
      else
        buffer << (buffer.empty? ? part : " #{part}")
      end
    end
    chunks << buffer if buffer.present?
    chunks
  end
end
