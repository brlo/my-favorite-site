module PagesHelper
  CHAT_INVITE_MIN_TEXT_LENGTH = 2000

  # Градиент подложки под заголовок на обложке: внизу почти непрозрачный, кверху сходит на нет
  def cover_overlay_gradient_style(page)
    r, g, b = page.cover_overlay_rgb
    "background: linear-gradient(to top, rgba(#{r}, #{g}, #{b}, 0.85) 0%, rgba(#{r}, #{g}, #{b}, 0) 60%);"
  end

  # Класс размера заголовка на обложке: чем длиннее заголовок, тем меньше шрифт.
  # Смотрим только на число символов: в азиатских языках пробелов может не быть.
  def cover_overlay_title_size_class(page)
    length = page.title.to_s.length
    return 'title-lg' if length > 50
    return 'title-md' if length > 25
  end

  # Пункт оглавления из номера главы ("3", " 12 ") ставим в строку с соседними, а не столбиком;
  # короткие слова и буквы ("Пс", "IV", "序") остаются на отдельной строке
  def toc_item_short?(text)
    text.to_s.strip.match?(/\A\d{1,3}\z/)
  end

  # Если все пункты «Похожих материалов» — только цифры/спецсимволы (#1, #2, 3),
  # то это переключатель частей одного материала, а не похожие страницы.
  def similar_materials_part?(chapters)
    chapters.present? && chapters.all? { |title, _path, _gold| title.to_s.match?(/\A[^\p{L}]+\z/) }
  end

  def similar_materials_title(chapters)
    similar_materials_part?(chapters) ? I18n.t('menu.same_subject_part') : I18n.t('menu.same_subject')
  end

  # Приглашение в чат показываем только под достаточно объёмной статьёй:
  # в коротких заметках обсуждать обычно нечего.
  def chat_invite_available?(page)
    return false if page.blank?

    strip_tags(page.body.to_s).squish.length >= CHAT_INVITE_MIN_TEXT_LENGTH
  end

  # JSON-LD по виду страницы (page.seo_kind): Person - автор, Book - книга, Article - обычная статья
  def page_structured_data(og_image)
    if @page.is_person_kind?
      person_structured_data(og_image)
    elsif @page.is_book_kind?
      book_structured_data(og_image)
    else
      article_structured_data(og_image)
    end
  end

  # og:type по виду страницы: profile у автора, book у книги, article у статьи
  def page_og_type
    return 'profile' if @page.is_person_kind?
    return 'book' if @page.is_book_kind?

    'article'
  end

  private

  def article_structured_data(og_image)
    JSON.generate(
      '@context' => 'https://schema.org',
      '@type' => 'Article',
      'headline' => @page.title,
      'inLanguage' => @content_lang,
      'datePublished' => @page.created_at&.iso8601,
      'dateModified' => @page.updated_at&.iso8601,
      'image' => og_image,
      'mainEntityOfPage' => @canonical_url,
      'author' => {'@type' => 'Organization', 'name' => I18n.t('title')},
      'publisher' => {'@type' => 'Organization', 'name' => I18n.t('title'), 'logo' => {'@type' => 'ImageObject', 'url' => my_res_link_to('/logo/bibleox.png')}},
    )
  end

  def person_structured_data(og_image)
    data = {
      '@context' => 'https://schema.org',
      '@type' => 'Person',
      'name' => @page.title,
      'description' => @page.title_sub.presence,
      'url' => @canonical_url,
      'image' => og_image,
    }
    dates = @page.life_dates
    data['birthDate'] = dates[:birth].to_s if dates[:birth]
    data['deathDate'] = dates[:death].to_s if dates[:death]
    JSON.generate(data)
  end

  def book_structured_data(og_image)
    data = {
      '@context' => 'https://schema.org',
      '@type' => 'Book',
      'name' => @page.title,
      'description' => @page.title_sub.presence,
      'url' => @canonical_url,
      'image' => og_image,
      'inLanguage' => @page.lang,
    }
    if (author = book_author_page)
      data['author'] = {'@type' => 'Person', 'name' => author.title, 'url' => author.canonical_url}
    end
    JSON.generate(data)
  end

  # автор книги: страница-автор (seo_kind=person), в чьём меню есть ссылка на эту книгу
  def book_author_page
    @book_author_page ||= begin
      menu_page_ids = ::Menu.where(path: @page.path).distinct.pluck(:page_id)
      ::Page.where(id: menu_page_ids, seo_kind: 'person').first
    end
  end
end
