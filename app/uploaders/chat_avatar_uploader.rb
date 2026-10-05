require_relative 'base_uploader'

class ChatAvatarUploader < BaseUploader
  def store_dir
    "s/img/chat_member/avatar/#{model.id}"
  end

  # аватар квадратный: обрезаем выступающие части
  process resize_to_fill: [256, 256]

  version :s do
    process resize_to_fill: [64, 64]
  end

  def extension_allowlist
    %w[jpg jpeg png webp gif]
  end

  def size_range
    1.byte..2.megabytes
  end
end
