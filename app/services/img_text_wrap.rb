class ImgTextWrap

  # Создать файл-картинку в "public/s/page_previews/#{page.id.to_s}.jpeg"
  # с названием статьи (page.title)
  def self.page_generate_img(page)
    img_text = page.title.to_s
    file_name = "public/s/page_previews/#{page.id.to_s}.jpeg"

    # # Создаем пустую картинку с заданными размерами, цветом фона и форматом
    background_image = Magick::Image.new(1200, 630) do |img|
      img.format = 'jpeg'
      img.background_color = '#f6f4e3'
    end

    # Сделал по этой доке:
    # https://livefiredev.com/in-depth-guide-rmagick-add-text-to-an-image-with-word-wrap/

    font_size = 75
    font_path = '/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf'
    width_of_bounding_box = 1100
    text_to_print = img_text

    # Create a new instance of the text wrap helper and give it all the
    # info the class needs..
    helper = ::ImgTextWrap.new(text_to_print, font_size, width_of_bounding_box, font_path)

    text = ::Magick::Draw.new
    text.pointsize = font_size
    text.gravity = ::Magick::CenterGravity
    text.fill = "#847e70"
    text.font = font_path

    # Call the "get_text_with_line_breaks" to get text
    # with line breaks where needed
    text_wit_line_breaks = helper.get_text_with_line_breaks

    text.annotate(background_image, 1200, 600, 0, 0, text_wit_line_breaks)

    background_image.write(file_name)
    background_image = nil
    GC.start
  end

  # -----------------------------------------------

  def initialize(text_to_print, font_size, width_of_bounding_box, path_to_font_file = nil)
    @text_to_print = text_to_print
    @font_size = font_size
    @path_to_font_file = path_to_font_file
    @width_of_bounding_box = width_of_bounding_box
  end

  def get_text_with_line_breaks
    fit_text(@text_to_print, @width_of_bounding_box)
  end

  def text_fit?(text, width)
    tmp_image = Magick::Image.new(width, 500)

    drawing = Magick::Draw.new

    drawing.gravity = Magick::CenterGravity
    drawing.pointsize = @font_size
    drawing.fill = "#ffffff"

    if @path_to_font_file
      drawing.font_family = @path_to_font_file
    end

    drawing.font_weight = Magick::BoldWeight
    drawing.annotate(tmp_image, 0, 0, 0, 0, text) do |text|
      text.font = "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf" # Font file; needs to be absolute
    end

    metrics = drawing.get_multiline_type_metrics(tmp_image, text)
    (metrics.width < width)
  end

  def fit_text(text, width)
    separator = ' '
    line = ''

    if not text_fit?(text, width) and text.include? separator
      i = 0
      text.split(separator).each do |word|
        if i == 0
          tmp_line = line + word
        else
          tmp_line = line + separator + word
        end

        if text_fit?(tmp_line, width)
          unless i == 0
            line += separator
          end
          line += word
        else
          unless i == 0
            line +=  '\n'
          end
          line += word
        end
        i += 1
      end
      text = line
    end
    text
  end
end
