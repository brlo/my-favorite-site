# Файлы страницы: pdf-версия и картинка для соцсетей
module Page::Files
  extend ActiveSupport::Concern

  # Ссылка на превьюшку страницы, для использования в html-meta
  # TODO: Перед удалением page, обязательно удали и картинку
  def img_preview_file_path
    page_img_path = "/s/page_previews/#{self.id.to_s}.jpeg"
    if ::File.exist?("public/#{page_img_path}")
      # Или автоматически сгенерированная картинка (название статьи на зелёном фоне)
      page_img_path
    else
      # Или логотип сайта
      "/favicons/bibleox-for-social-#{ ::I18n.locale == :ru ? 'ru' : 'en' }.png"
    end
  end

  # Аудио к странице: /public/s/audio/pages/ru/fathers/01_ign_ant/ef.mp3
  # В статье указывается только это: fathers/01_ign_ant/ef
  def audio_link(content_lang)
    file = "/s/audio/pages/#{content_lang}/#{self.audio}"
    file if ::File.exist?("#{Rails.root}/public#{file}.mp3")
  end

  def generate_img
    ::ImgTextWrap.page_generate_img(self)
  end

  def pdf_path
    if self.h_id.present?
      p = "s/page_pdfs/#{self.h_id}.pdf"
      return p if ::File.exist?(Rails.root.join('public', p))
    end

    "s/page_pdfs/#{self.id}.pdf"
  end

  def pdf_exists?
    ::File.exist?(Rails.root.join('public', pdf_path))
  end

  def remove_pdf!
    ::File.delete(Rails.root.join('public', pdf_path)) if pdf_exists?
  end
end
