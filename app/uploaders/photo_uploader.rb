require_relative "base_uploader"
class PhotoUploader < BaseUploader

  version :m do
    process :resize_to_limit_with_fill => [800, 800]
  end

  version :s, :from_version => :m do
    process :resize_to_limit_with_fill => [465, 465]
  end

end
