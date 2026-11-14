module PagesHelper
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
end
