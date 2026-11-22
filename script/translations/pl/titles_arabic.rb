# Римские обозначения частей в заголовках латинских страниц → арабские.
require_relative '/app/script/translations/pl/menu_tidy'
dry = ENV['DRY_RUN'].present?
n = 0
Page.where(lang: 'la', page_type: 1).find_each do |p|
  t = MenuTidy.convert(p.title)
  next if t == p.title
  n += 1
  if dry
    puts "#{p.path}: #{p.title.inspect} → #{t.inspect}"
  else
    p.update_columns(title: t)
  end
end
puts "изменено заголовков: #{n}"
