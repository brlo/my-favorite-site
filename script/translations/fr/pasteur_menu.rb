# frozen_string_literal: true

# «Пастырь Ерма» во французском разделе должен лежать как в русском эталоне:
# не прямо под заголовком века в меню раздела, а внутри подраздела
# «Œuvres du Ier siècle d'auteurs inconnus» (аналог «Труды I века неизвестных
# авторов»), в группе «Autres écrits».
#
# Перед запуском импортировать страницу-подраздел:
#   bin/rails pages:import_translations FILE=db/translations/fr/hrms_00_list.yml [DRY_RUN=1] [PUBLISH=1]
# Затем:
#   bin/rails runner script/translations/fr/pasteur_menu.rb [DRY_RUN=1]
#
# Без DRY_RUN=1 скрипт считает план, но откатывает транзакцию и в БД ничего не пишет.
# Идемпотентен.

SECTION_PATH = '4saQ_Ouvrages_des_anciens_chrétiens'
LIST_PATH = '2Cdc_Œuvres_du_Ier_siècle_dauteurs_inconnus'
PASTEUR_PATH = 'Hrms_Le_Pasteur'
DIDACHE_PATH = 'rHXL_Didachè_IIIe_s'
DIDACHE_MENU_TITLE = 'Didachè — Doctrine des douze Apôtres'
LIST_ITEM_TITLE = "Œuvres du Ier siècle d'auteurs inconnus"

is_dry_run = ARGV.include?('DRY_RUN=1') || ENV['DRY_RUN'].present?

section = ::Page.find_by(lang: 'fr', path: SECTION_PATH)
abort "нет французского раздела #{SECTION_PATH}" unless section
list = ::Page.find_by(lang: 'fr', path: LIST_PATH)
unless list
  abort "нет страницы подраздела #{LIST_PATH} — сначала импортируйте db/translations/fr/hrms_00_list.yml"
end
pasteur = ::Page.find_by(lang: 'fr', path: PASTEUR_PATH)
abort "нет страницы #{PASTEUR_PATH}" unless pasteur
didache = ::Page.find_by(lang: 'fr', path: DIDACHE_PATH)

::ActiveRecord::Base.transaction do
  # 1. Пункт века в меню раздела: заготовка уже есть, ведём её на подраздел
  century = ::Menu.find_by(page_id: section.id, parent_id: nil, title: 'Ier siècle')
  abort 'нет группы «Ier siècle» в меню раздела' unless century
  list_item = ::Menu.find_by(page_id: section.id, parent_id: century.id, title: LIST_ITEM_TITLE)
  abort "нет пункта «#{LIST_ITEM_TITLE}» в группе «Ier siècle»" unless list_item
  if list_item.path == LIST_PATH
    puts "меню раздела: «#{LIST_ITEM_TITLE}» уже ведёт на подраздел"
  else
    puts "#{is_dry_run ? '[DRY RUN] ' : ''}меню раздела: «#{LIST_ITEM_TITLE}»: #{list_item.path.inspect} -> #{LIST_PATH}"
    list_item.update!(path: LIST_PATH)
  end

  # 2. Папки внутри подраздела — как «Наставления»/«Прочее» в русском
  folder_titles = { 'Enseignements' => 1, 'Autres écrits' => 2 }
  folders = folder_titles.to_h do |title, priority|
    folder = ::Menu.find_by(page_id: list.id, parent_id: nil, title: title)
    unless folder
      puts "#{is_dry_run ? '[DRY RUN] ' : ''}меню подраздела: папка «#{title}»"
      folder = ::Menu.create!(page_id: list.id, title: title, priority: priority)
    end
    [title, folder]
  end

  # 3. Труд «Le Pasteur» переезжает из меню раздела в меню подраздела
  legacy_items = ::Menu.where(page_id: section.id, path: PASTEUR_PATH).to_a
  current_item = ::Menu.find_by(page_id: list.id, path: PASTEUR_PATH)
  if current_item.nil? && legacy_items.present?
    item = legacy_items.shift
    puts "#{is_dry_run ? '[DRY RUN] ' : ''}меню: «Le Pasteur»: раздел -> «Autres écrits» подраздела"
    item.update!(page_id: list.id, parent_id: folders['Autres écrits'].id, title: 'Le Pasteur', priority: 1)
    current_item = item
  elsif current_item.nil?
    puts "#{is_dry_run ? '[DRY RUN] ' : ''}меню подраздела: «Le Pasteur» -> #{PASTEUR_PATH}"
    current_item = ::Menu.create!(
      page_id: list.id, parent_id: folders['Autres écrits'].id,
      title: 'Le Pasteur', path: PASTEUR_PATH, priority: 1,
    )
  else
    puts 'меню подраздела: «Le Pasteur» уже на месте'
  end
  unless legacy_items.empty?
    puts "#{is_dry_run ? '[DRY RUN] ' : ''}меню: лишние пункты «Le Pasteur» в разделе — удалить (#{legacy_items.size})"
    legacy_items.each(&:destroy!)
  end

  # 4. Дидахе — в группу «Enseignements», как «Дидахе — учение 12 апостолов» в русском
  if didache
    if ::Menu.exists?(page_id: list.id, path: DIDACHE_PATH)
      puts 'меню подраздела: «Didachè» уже на месте'
    else
      puts "#{is_dry_run ? '[DRY RUN] ' : ''}меню подраздела: «Enseignements → Didachè» -> #{DIDACHE_PATH}"
      ::Menu.create!(
        page_id: list.id, parent_id: folders['Enseignements'].id,
        title: DIDACHE_MENU_TITLE, path: DIDACHE_PATH, priority: 1,
      )
    end
    if didache.parent_id != list.id
      puts "#{is_dry_run ? '[DRY RUN] ' : ''}«Didachè»: родитель #{didache.parent&.path.inspect} -> #{LIST_PATH}"
      didache.update!(parent_id: list.id)
    end
  end

  # 5. Сам труд «Le Pasteur» становится дочерним к подразделу (как в en/grc)
  if pasteur.parent_id != list.id
    puts "#{is_dry_run ? '[DRY RUN] ' : ''}«Le Pasteur»: родитель #{pasteur.parent&.path.inspect} -> #{LIST_PATH}"
    pasteur.update!(parent_id: list.id)
  end

  raise ::ActiveRecord::Rollback if is_dry_run
end

puts is_dry_run ? 'План проверен, изменения откатаны' : 'Готово'
