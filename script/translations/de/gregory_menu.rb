# frozen_string_literal: true

# Заготовки трудов Григория Чудотворца, которых нет в BKV (как в RU-меню).
#   bin/rails runner script/translations/de/gregory_menu.rb [APPLY=1]

apply = ARGV.include?('APPLY=1')
author = ::Page.find_by!(lang: 'de', path: 'Gregor_der_Wundertäter')
folder = ::Menu.find_by!(page_id: author.id, parent_id: nil, title: 'Werke')

[
  ['Übertragung des Ekklesiastes', 2],
  ['An Theopompus über die Möglichkeit und Unmöglichkeit des Leidens Gottes', 3],
].each do |title, priority|
  menu = ::Menu.find_by(page_id: author.id, parent_id: folder.id, title: title)
  if menu.nil?
    puts "создать заготовку: #{title}"
    ::Menu.create!(page_id: author.id, parent_id: folder.id, title: title,
                   priority: priority, is_gold: false) if apply
  elsif menu.priority != priority
    puts "priority #{title}: #{menu.priority} -> #{priority}"
    menu.update!(priority: priority) if apply
  end
end

['Glaubensbekenntnis', 'Lobrede auf Origenes'].each_with_index do |title, i|
  menu = ::Menu.find_by(page_id: author.id, parent_id: folder.id, title: title)
  next if menu.nil?

  priority = i.zero? ? 1 : 4
  menu.update!(priority: priority) if menu.priority != priority && apply
end

puts apply ? 'ПРИМЕНЕНО' : 'DRY RUN (APPLY=1 для записи)'
