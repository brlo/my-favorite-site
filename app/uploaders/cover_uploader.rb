require_relative 'base_uploader'

class CoverUploader < BaseUploader

  # обработка оригинала
  process resize_to_fit: [2000, 1400]

  version :large do
    # доступные способы обработки изображений:
    # https://github.com/carrierwaveuploader/carrierwave?tab=readme-ov-file#list-of-available-processing-methods

    # вписать в область, ничего не отрезая, сохраняя соотношения сторон
    process resize_to_fit: [1200, 800]
    # # вписать в область, отрезав выступ, сохраняя соотношения сторон
    # process resize_to_fill: [1200, 400]

    # --- старое:

    # Вписать всю картинку в область без обрезаний
    # process resize_to_limit: [1180, 400]

    # ЭТО СТАРАЯ КАСТОМНАЯ ФУНКЦИЯ. Не понял, чем она отличается от resize_to_fill:
    # вписать в область, обрезав выступающие части
    # process resize_to_limit_with_fill: [1180, 400]
  end

  # иконки для менюшек
  # TIP! Если после добавления версии захочешь для старых картинок создать эту версию, делай так:
  # Page.order_by(u_at: :asc).last(20).map{ _1.cover.recreate_versions!(:micro) }
  # version :micro do
  #   process resize_to_fit: [90, 70]
  # end

  # Ограничиваем допустимый размер картинок (для этого просто создаётся этот метод)
  # doc: https://github.com/carrierwaveuploader/carrierwave/wiki/How-to:-Validate-image-file-size
  def size_range
    1.byte..1.megabytes
  end
end
