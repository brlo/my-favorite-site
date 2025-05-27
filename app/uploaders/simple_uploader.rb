require_relative "base_uploader"
class SimpleUploader < BaseUploader

  # обработка оригинала
  process resize_to_fit: [2000, 1400]

  version :m do
    process :resize_to_fit => [1600, 1200]
  end

  version :s, :from_version => :m do
    process :resize_to_fit => [265, 265]
  end

  # Ограничиваем допустимый размер картинок (для этого просто создаётся этот метод)
  # doc: https://github.com/carrierwaveuploader/carrierwave/wiki/How-to:-Validate-image-file-size
  def size_range
    1.byte..5.megabytes
  end
end
