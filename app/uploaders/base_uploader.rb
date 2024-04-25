class BaseUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  # before :cache, :log_cache
  # before :process, :log_process
  # before :remove, :log_remove
  # before :retrieve_from_cache, :log_retrieve_from_cache
  # before :store, :log_store

  SAVING_FORMAT             = "jpg".freeze
  VERSIONS_COMPRESS_QUALITY = "70".freeze
  ORIGINAL_COMPRESS_QUALITY = "80".freeze

  # на stage и в prod в имени файла используем префикс и специальный хост для ссылок
  # PROD
  if ::Rails.env.production?
    PREFIX = 'p_'.freeze
    BASE_URL_FOR_ALL =    'https://res.bibleox.com'.freeze
    BASE_URL_FOR_PREFIX = 'https://res.bibleox.com'.freeze

  # DEV
  else
    PREFIX = 'd_'.freeze
    BASE_URL_FOR_ALL =    'https://res.bibleox.com'.freeze
    # разработчик смотрит файлы на своём компьютере, поэтому абсолютный пуль не нужен
    BASE_URL_FOR_PREFIX = 'http://bibleox.lan'
  end

  ## accept only this formats
  # def extension_allowlist
  #   %w(jpg jpeg gif png)
  # end

  # Оригинал подлежит лишь конвертированию в jpg
  # остальные версии конвертируются в jpg в процессе создания подходящего размера
  process :convert_to_jpg, :if => :original?

  def filename
    "#{PREFIX}#{ secure_token(length: 16) }.#{ saving_format }" if original_filename.present?
  end

  def store_dir
    "s/img/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def recreate_versions_from_cache! options = {}
    use_old_name = options[:use_old_name] || false
    cache_stored_file!
    retrieve_from_cache!(cache_name)
    secure_token(token: file.basename) if use_old_name
    recreate_versions!
  end

  def recreate_versions_from_cache_and_save! options = {}
    recreate_versions_from_cache!(use_old_name: options[:use_old_name])
    model.save!
  end

  # вместо #url, т.к. надо немного изменить поведение: отдавать stage и prod
  # ссылки в одном приложении
  def url(options = {})
    # отдаём обычный url везде, кроме stage
    return(super) unless need_custom_url?()

    if file.respond_to?(:path)
      # path = file.path
      path = "#{store_dir}/#{file.filename}"

      # Префикс имени файла:
      # 'thumb_st_'
      # 'st_'
      name_prefix = [version_name, PREFIX].compact.join('_')

      # проверяем, начинается ли имя с особенного префикса
      if file.filename.to_s.starts_with?(name_prefix)
        # ссылка для файла с префиксом
        "#{BASE_URL_FOR_PREFIX}/#{path}"
      else
        # обычная ссылка для всех
        "#{BASE_URL_FOR_ALL}/#{path}"
      end
    end
  end

  def urls
    self.versions.transform_values { |v| v.url } # .merge(original: self.url)
  end

  # чтобы в консоли у мастера красиво отображался inspect (иначе полотенце будет)
  def inspect
    # можно было бы и urls вызвать, были бы все версии
    "#<#{self.class.name}: url: #{self.url || 'nil'}>"
  end

  def to_s
    self.url || '' # было .url
  end

  def to_h
    self.urls
  end

  protected

  def saving_format
    SAVING_FORMAT
  end

  def resize_to_limit_with_fill(width, height, gravity = 'Center', combine_options: {})
    manipulate! do |img|
      cols, rows = img[:dimensions]
      img.format(saving_format) do |cmd|
        cmd.auto_orient
        cmd.quality(VERSIONS_COMPRESS_QUALITY)
        cmd.gravity gravity
        cmd.background "rgba(255,255,255,0.0)"
        cmd.depth "8" # Set the depth to 8 bits
        # progressive jpeg: http://stackoverflow.com/questions/9855637/how-do-you-generate-retina-ipad-friendly-progressive-or-interlaced-jpeg-imag
        cmd.interlace "plane"

        if cols > width or rows > height
          # Calculating which side is bigger
          # then reduce scale to match smaller
          if width != cols || height != rows
            scale_x = width/cols.to_f
            scale_y = height/rows.to_f
            if scale_x >= scale_y
              cols = (scale_x * (cols + 0.5)).round
              rows = (scale_x * (rows + 0.5)).round
              cmd.resize "#{cols}"
            else
              cols = (scale_y * (cols + 0.5)).round
              rows = (scale_y * (rows + 0.5)).round
              cmd.resize "x#{rows}"
            end
          end

          # Crop
          cmd.extent "#{width}x#{height}" if cols >= width || rows >= height
        end

        append_combine_options cmd, combine_options
      end
      img.strip
      img = yield(img) if block_given?
      img
    end
  end

  def convert_to_jpg
    manipulate! do |img|
      img.format("jpg") do |cmd|
        cmd.auto_orient
        cmd.quality(ORIGINAL_COMPRESS_QUALITY)
        cmd.gravity 'Center'
        cmd.background "rgba(255,255,255,0.0)"
        cmd.depth "8" # Set the depth to 8 bits
        # progressive jpeg: http://stackoverflow.com/questions/9855637/how-do-you-generate-retina-ipad-friendly-progressive-or-interlaced-jpeg-imag
        cmd.interlace "plane"
      end
      ## Erase meta-information for original images
      # img.strip
      img
    end
  end

  ## НЕ РЕКОМЕНДУЕТСЯ ИСПОЛЬЗОВАТЬ ЭТУ ПРОВЕРКУ. ВОЗМОЖНЫ FALSE POSITIVE
  ## Ранее, всем версиям было выставлено условие, что они создаются только если if: :image?
  ## это приводило к тому, что версии не всегда создавались, ввиду отсутствия у некоторых файлов content_type.
  ## Так же, иногда content_type может иметь такой вид 'application/png'
  ## При этом, если несколько раз загружать картинку, или несколько раз пересоздавать версии,
  ## то content_type появлялся и версии создавались.
  # def image?(new_file)
  #   new_file.content_type.start_with? 'image'
  # end

  def original? file=nil
    version_name.blank?
  end

  def append_combine_options(cmd, combine_options)
    combine_options.each do |method, options|
      cmd.send(method, options)
    end
  end

  def secure_token options = {}
    length = options[:length] || 16
    token  = options[:token]  || ::StringRandom.get(length)
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) or model.instance_variable_set(var, token)
  end

  def need_custom_url?
    true
  end

  # # temp_file то же что и @file
  # def log_cache temp_file = nil
  #   puts "[FILE] Caching file (#{self.class.name}): #{@file.class.name}, #{@file&.path}"
  # end

  # def log_process temp_file = nil
  #   puts "[FILE] Process file (#{self.class.name}): #{@file.class.name}, #{@file&.path}"
  # end

  # def log_remove temp_file = nil
  #   puts "[FILE] Removing file (#{self.class.name}): #{@file.class.name}, #{@file&.path}"
  # end

  # def log_retrieve_from_cache temp_file = nil
  #   puts "[FILE] Retrieve from cache file (#{self.class.name}): #{@file.class.name}, #{@file&.path}"
  # end

  # def log_store temp_file = nil
  #   puts "[FILE] Store file (#{self.class.name}): #{@file.class.name}, #{@file&.path}"
  # end
end
