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
end
