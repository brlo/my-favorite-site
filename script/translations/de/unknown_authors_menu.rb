# frozen_string_literal: true

# Как в RU: «Послание Варнавы» лежит в «Трудах I века неизвестных авторов»
# (категория «Прочее»), а не в меню автора; страница автора остаётся без
# ссылки из библиотеки. Авторство послания спорно.
#
#   bin/rails runner script/translations/de/unknown_authors_menu.rb [APPLY=1]

apply = ARGV.include?('APPLY=1')
list = ::Page.find_by!(lang: 'de', path: 'Kirchenvaeter')
unknown = ::Page.find_by!(lang: 'de', path: 'Werke_unbekannter_Autoren_des_1_Jahrhunderts')
author = ::Page.find_by!(lang: 'de', path: 'Barnabas')
work = ::Page.find_by!(lang: 'de', path: 'Barnabasbrief')

def folder(page, title, priority, apply)
  menu = ::Menu.find_by(page_id: page.id, parent_id: nil, title: title)
  if menu.nil?
    puts "создать папку: #{title}"
    menu = ::Menu.create!(page_id: page.id, title: title, priority: priority) if apply
  elsif menu.priority != priority
    puts "папка #{title}: priority #{menu.priority} -> #{priority}"
    menu.update!(priority: priority) if apply
  end
  menu
end

unterweisungen = folder(unknown, 'Unterweisungen', 1, apply)
uebriges = folder(unknown, 'Übriges', 4, apply)

if apply
  didache = ::Menu.find_by(page_id: unknown.id, path: 'Didache_Lehre_der_zwolf_Apostel')
  if didache
    puts "Didache: parent #{didache.parent_id} -> #{unterweisungen.id}"
    didache.update!(parent_id: unterweisungen.id, priority: 1) if didache.parent_id != unterweisungen.id || didache.priority != 1
  end

  barn = ::Menu.find_by(page_id: unknown.id, path: 'Barnabasbrief')
  if barn.nil?
    puts 'создать: Barnabasbrief в «Übriges»'
    ::Menu.create!(page_id: unknown.id, parent_id: uebriges.id, title: 'Barnabasbrief',
                   path: 'Barnabasbrief', priority: 5, is_gold: false)
  else
    barn.update!(parent_id: uebriges.id, priority: 5) if barn.parent_id != uebriges.id || barn.priority != 5
  end

  removed = ::Menu.where(page_id: author.id).delete_all
  puts "удалено пунктов меню автора: #{removed}" if removed.positive?
  removed = ::Menu.where(page_id: list.id, path: 'Barnabas').delete_all
  puts "удалено пунктов автора из списка: #{removed}" if removed.positive?
else
  puts 'создать папки Unterweisungen/Übriges и перенести Didache/Barnabasbrief'
  puts 'удалить пункт автора Barnabas из списка и меню автора'
end

puts apply ? 'ПРИМЕНЕНО' : 'DRY RUN (APPLY=1 для записи)'
