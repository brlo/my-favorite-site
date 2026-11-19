# Переименование ko-страниц авторов: имя на первом месте (правило 19.11).
# Обновляет pages.title и пункт меню автора (меню ищется по path — у пунктов
# авторов page_id указывает на раздел); пути не трогает.
# Запуск: bin/rails runner script/translations/ko_author_titles.rb    (dry run)
#         APPLY=1 bin/rails runner ...                                (запись)
RENAME = [
  ['ig2a_', '이그나티오스 (테오포로스), 1세기', '이그나티오스 (테오포로스), 순교자 (~35-107)'],
].freeze

APPLY = ENV['APPLY'] == '1'

RENAME.each do |pfx, new_title, new_menu|
  page = Page.where('path_low LIKE ?', "#{pfx}%").order(:id).first
  abort "!! страница не найдена: #{pfx}" unless page
  items = Menu.where('path ILIKE ?', "#{pfx}%")
  puts "== #{page.id} #{page.path}"
  puts "   title: #{page.title} -> #{new_title}"
  items.each { |m| puts "   menu #{m.id}: #{m.title} -> #{new_menu}" }
  abort "!! пунктов меню с путём #{pfx}: #{items.size}" unless items.size == 1
  next unless APPLY
  page.update!(title: new_title)
  items.each { |m| m.update!(title: new_menu) }
end
puts APPLY ? 'ПРИМЕНЕНО' : 'DRY RUN (APPLY=1 для записи)'
