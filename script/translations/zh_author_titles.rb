# Переименование zh-страниц авторов: имя на первом месте (правило 19.11).
# Обновляет pages.title и пункт меню автора (меню ищется по path — у пунктов
# авторов page_id указывает на раздел); пути не трогает.
# Запуск: bin/rails runner tmp/zh_author_titles.rb            (dev, dry run)
#         APPLY=1 bin/rails runner ...                        (запись)
RENAME = [
  # [префикс path (case-insensitive), новый title страницы, новый title пункта меню]
  ['ig4a_', '伊格那丢（提阿弗罗斯），一世纪',          '伊格那丢（提阿弗罗斯），殉道者（约35-107年）'],
  ['pk4a_', '坡旅甲（士每拿的），一至二世纪',           '坡旅甲（士每拿的），主教，殉道者（约69–155年）'],
  ['kl4a_', '革利免（罗马的），一世纪',                '革利免（罗马的），主教，殉道者（†约101年）'],
  ['b6ax_', '圣索弗罗尼（耶路撒冷牧首），六至七世纪',  '圣索弗罗尼（耶路撒冷圣宗主教），约560-638年'],
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
