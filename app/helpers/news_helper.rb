module NewsHelper
  # Если у статьи нет метки деления, показываем в ленте текстовый анонс:
  # целый текст статьи в карточке был бы неуместен.
  NEWS_EXCERPT_LENGTH = 800

  def news_page_link(page)
    my_page_link_to("/#{::CGI.escape(page.path)}", page_lang: page.lang)
  end

  def news_preview(page)
    if page.body_lead.present?
      content_tag(:div, news_lead_html(page).html_safe, class: 'news-card__lead')
    else
      text = strip_tags((page.body_rendered.presence || page.body).to_s).squish
      content_tag(
        :div,
        simple_format(truncate(text, length: NEWS_EXCERPT_LENGTH, separator: ' ')),
        class: 'news-card__lead news-card__lead--excerpt',
      )
    end
  end

  # В ленте несколько карточек сразу: id из статьи (сноски, заголовки) дали бы
  # дубликаты, а ссылки вида #fn1 вели бы внутрь ленты. Ведём их на страницу статьи.
  def news_lead_html(page)
    fragment = ::Nokogiri::HTML::DocumentFragment.parse(page.body_lead)
    page_link = news_page_link(page)

    fragment.css('a[href^="#"]').each { |link| link['href'] = "#{page_link}#{link['href']}" }
    fragment.css('[id]').each { |node| node.remove_attribute('id') }

    fragment.to_html
  end

  def news_author_name(page)
    page.user&.name.presence || ::I18n.t('news.editorial')
  end
end
