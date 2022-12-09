module ApplicationHelper
  # размеры текста для пользователя (выбирается в шапке)
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

  # Очистка одного стиха от спец. символов в конце (для поисковой страницы)
  def verse_alone_clean text
    if text[-1] =~ /[\.\,\-\;\:]/
      text[0..-2]
    else
      text
    end
  end

  # Пользовательский размер текста из кук
  def text_size_from_cookies
    # Определяем размер текста по кукам.
    # Если в куках пусто или непонятно что, то берём значение по-умолчанию
    @text_size_from_cookies ||= TEXT_SIZES[cookies[:textSize]] || TEXT_SIZES[nil]
  end

  # Делает ссылку с указанной локалью (текущей)
  def my_link_to(path)
    "/#{I18n.locale}#{path}"
  end

  # ссылка на ресурс
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
