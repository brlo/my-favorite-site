# Выбор локали интерфейса по заголовку Accept-Language.
#
# Задача — не гадать по IP, а уважать языковые предпочтения браузера:
# японец с ja-JP должен попасть на /ja/, китаец с zh-CN — на /zh-Hans/,
# а с zh-TW/zh-HK — на /zh-Hant/. Если ничего не подошло, остаётся
# текущее поведение сайта — русская главная.
class AcceptLanguage
  # Китайский в Accept-Language приходит регионами, а на сайте две графики.
  LOCALE_ALIASES = {
    'zh' => 'zh-Hans',
    'zh-cn' => 'zh-Hans',
    'zh-sg' => 'zh-Hans',
    'zh-my' => 'zh-Hans',
    'zh-tw' => 'zh-Hant',
    'zh-hk' => 'zh-Hant',
    'zh-mo' => 'zh-Hant',
  }.freeze

  MAX_HEADER_LENGTH = 500

  # Возвращает ключ из available (например, 'zh-Hant'), либо default.
  def self.best_locale(header, available: ::ALL_LOCALES.keys, default: 'ru')
    return default if header.blank?

    preferred_tags(header).each do |tag|
      locale = match(tag, available)
      return locale if locale
    end

    default
  end

  # Пары [тег, q] по убыванию q; при равном q сохраняется порядок из заголовка.
  def self.preferred_tags(header)
    header.to_s[0, MAX_HEADER_LENGTH].split(',').filter_map.with_index do |part, index|
      tag, *params = part.strip.split(';')
      next if tag.blank? || tag == '*'

      q = 1.0
      params.each do |param|
        key, value = param.strip.split('=', 2)
        q = value.to_f if key == 'q'
      end
      next if q <= 0

      [tag.downcase, q, index]
    end.sort_by { |_tag, q, index| [-q, index] }.map { |tag, _q, _index| tag }
  end

  # Пробуем точный тег, затем всё более короткие: zh-Hant-TW -> zh-Hant -> zh.
  def self.match(tag, available)
    parts = tag.split('-')
    while parts.any?
      candidate = parts.join('-')
      mapped = LOCALE_ALIASES.fetch(candidate, candidate)
      found = available.find { |locale| locale.to_s.downcase == mapped.downcase }
      return found if found

      parts.pop
    end

    nil
  end
end
