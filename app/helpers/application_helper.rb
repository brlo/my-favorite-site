module ApplicationHelper
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
