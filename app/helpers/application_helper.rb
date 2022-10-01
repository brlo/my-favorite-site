module ApplicationHelper
  TEXT_SIZES = {
    '1' => 'small',
    '2' => 'medium',
    '3' => 'large',
    nil => 'small'
  }
  # def current_lang
  #   lang = cookies[:'b-lang']

  #   if ['ru', 'csl-pnm', 'csl-ru'].include?(lang)
  #     lang
  #   else
  #     'ru'
  #   end
  # end

  def verse_alone_clean text
    if text[-1] =~ /[\.\,\-\;\:]/
      text[0..-2]
    else
      text
    end
  end

  def text_size_from_cookies
    # Определяем размер текста по кукам.
    # Если в куках пусто или непонятно что, то берём значение по-умолчанию
    @text_size_from_cookies ||= TEXT_SIZES[cookies[:textSize]] || TEXT_SIZES[nil]
  end

  def my_link_to(path)
    "/#{I18n.locale}#{path}"
  end

  if Rails.env.production?
    def my_res_link_to(path)
      "https://res.bibleox.com#{path}"
    end
  else
    def my_res_link_to(path)
      path
    end
  end
end
