# frozen_string_literal: true

# Наполняет меню библиотеки переводами: века → авторы по русскому эталону.
# Создаёт недостающие папки-века и пункты авторов (без path, если страницы
# перевода ещё нет), обновляет существующие (место, priority, is_gold, title).
#
# Вход:
#   db/translations/library_menu_targets.yml — снимок RU-меню
#   db/translations/library_menu_titles_de.yml / _fr.yml — переводы названий
#
#   bin/rails runner script/translations/fill_library_menus.rb de [APPLY=1] [RESET=1]
#   bin/rails runner script/translations/fill_library_menus.rb fr [APPLY=1] [RESET=1]
#
# RESET=1 удаляет пустые пункты-заготовки под списком (не папки) и строит
# меню заново по снимку; пункты с путями (реальные страницы) сохраняются.
#
# Без APPLY=1 — только отчёт.

require 'yaml'

LISTS = {
  'de' => 'Kirchenvaeter',
  'fr' => '4saQ_Ouvrages_des_anciens_chrétiens',
}.freeze

# RU-папка -> [немецкое название, французское название, priority]
FOLDERS = {
  'I век (создание новозаветной Церкви)' => ['1. Jahrhundert', 'Ier siècle', 1],
  'II век' => ['2. Jahrhundert', 'IIe siècle', 2],
  'III век' => ['3. Jahrhundert', 'IIIe siècle', 3],
  'IV век (прекращение римских гонений на христиан, начало эпохи Вселенских Соборов)' =>
    ['4. Jahrhundert', 'IVe siècle', 4],
  'V век' => ['5. Jahrhundert', 'Ve siècle', 5],
  'VI век' => ['6. Jahrhundert', 'VIe siècle', 6],
  'VII век' => ['7. Jahrhundert', 'VIIe siècle', 7],
  'VIII век' => ['8. Jahrhundert', 'VIIIe siècle', 8],
  'IX век (конец эпохи Вселенских Соборов)' => ['9. Jahrhundert', 'IXe siècle', 9],
  'XI век (отпадение Римской Церкви от Православия)' => ['11. Jahrhundert', 'XIe siècle', 11],
  'XIV век' => ['14. Jahrhundert', 'XIVe siècle', 14],
  'XVI век' => ['16. Jahrhundert', 'XVIe siècle', 16],
  'XVII век' => ['17. Jahrhundert', 'XVIIe siècle', 17],
  'XVIII век' => ['18. Jahrhundert', 'XVIIIe siècle', 18],
  'XIX век' => ['19. Jahrhundert', 'XIXe siècle', 19],
  'XX век' => ['20. Jahrhundert', 'XXe siècle', 20],
  'Катехизис' => ['Katechismus', 'Catéchismes', 500],
  'Сборники изречений' => ['Sammlungen von Aussprüchen', 'Recueils de sentences', 100],
}.freeze

lang = ARGV.find { |arg| !arg.include?('=') } || abort('укажите язык: de или fr')
apply = ARGV.include?('APPLY=1')
list_path = LISTS[lang] or abort("нет списка для #{lang}")
titles_file = "db/translations/library_menu_titles_#{lang}.yml"
abort("нет #{titles_file}") unless File.exist?(titles_file)

titles = YAML.safe_load(File.read(titles_file)).to_h { |h| [h.fetch('path'), h.fetch('title')] }
targets = YAML.safe_load(File.read('db/translations/library_menu_targets.yml'))
list = ::Page.find_by(lang: lang, path: list_path) or abort("нет списка #{list_path}")

reset = ARGV.include?('RESET=1')
if reset && apply
  removed = ::Menu.where(page_id: list.id).where.not(parent_id: nil).where(path: [nil, '']).delete_all
  puts "удалено заготовок: #{removed}"
end

group_counts = targets.group_by { |r| r['group'].presence || r.fetch('path') }.transform_values(&:size)

created = updated = 0
targets.each do |row|
  de_title, fr_title, folder_priority = FOLDERS[row.fetch('parent')]
  next if de_title.nil?

  folder_title = lang == 'de' ? de_title : fr_title
  folder = ::Menu.find_by(page_id: list.id, parent_id: nil, title: folder_title)
  if folder.nil?
    puts "папка: #{folder_title}"
    folder = ::Menu.create!(page_id: list.id, title: folder_title, priority: folder_priority) if apply
    next unless apply
  elsif folder.priority != folder_priority
    puts "папка #{folder_title}: priority #{folder.priority} -> #{folder_priority}"
    folder.update!(priority: folder_priority) if apply
  end
  next unless folder

  ru_page = ::Page.find_by(lang: 'ru', path: row['path'])
  tr_page = if ru_page
              ::Page.find_by(group_lang_id: ru_page.group_lang_id, lang: lang)
            end
  tr_title = titles[row.fetch('path')] || row.fetch('title')

  item = if tr_page
           ::Menu.find_by(page_id: list.id, parent_id: folder.id, path: tr_page.path)
         else
           ::Menu.find_by(page_id: list.id, parent_id: folder.id, path: [nil, ''], title: tr_title)
         end
  # один и тот же путь может стоять в двух папках (автор + катехизис) — тогда
  # ищем только в своей папке и при необходимости создаём второй пункт
  if item.nil? && tr_page && group_counts[ru_page.group_lang_id].to_i == 1
    item = ::Menu.find_by(page_id: list.id, path: tr_page.path)
  end

  if item
    attrs = { parent_id: folder.id, priority: row['priority'], is_gold: row['is_gold'] }
    attrs[:title] = tr_title if item.title.blank?
    attrs[:path] = tr_page.path if tr_page && item.path != tr_page.path
    changed = attrs.reject { |k, v| item.public_send(k) == v }
    next if changed.empty?

    puts "  обновить: #{item.title} -> #{tr_title} (#{changed.keys.join(', ')})"
    item.update!(changed) if apply
    updated += 1
  else
    puts "  создать: #{tr_title}#{tr_page ? " -> #{tr_page.path}" : ' (без ссылки)'}"
    if apply
      ::Menu.create!(page_id: list.id, parent_id: folder.id, title: tr_title,
                     path: tr_page&.path, priority: row['priority'], is_gold: row['is_gold'])
    end
    created += 1
  end
end

puts "#{apply ? '' : 'DRY RUN '}создано: #{created}, обновлено: #{updated}"
