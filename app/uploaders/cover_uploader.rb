require_relative 'base_uploader'

class CoverUploader < BaseUploader
  version :large do
    # Вписать всю картинку в область без обрезаний
    # process resize_to_limit: [1920, 200]

    # вписать в область, обрезав выступающие части
    process resize_to_limit_with_fill: [1180, 400]
  end
end
