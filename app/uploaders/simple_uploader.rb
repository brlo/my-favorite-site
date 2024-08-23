require_relative "base_uploader"
class SimpleUploader < BaseUploader

  version :m do
    process :resize_to_fit => [1200, 800]
  end

  version :s, :from_version => :m do
    process :resize_to_fit => [265, 265]
  end

end
