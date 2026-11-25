# frozen_string_literal: true

# Категории и заготовки меню Киприана по RU (письма, недостающие трактаты).
#   bin/rails runner script/translations/de/cyprian_menu.rb [APPLY=1]

apply = ARGV.include?('APPLY=1')
author = ::Page.find_by!(lang: 'de', path: 'Cyprian_von_Karthago')

def folder(author, title, priority, apply)
  menu = ::Menu.find_by(page_id: author.id, parent_id: nil, title: title)
  if menu.nil?
    puts "создать папку: #{title}"
    menu = ::Menu.create!(page_id: author.id, title: title, priority: priority) if apply
  elsif menu.priority != priority
    puts "priority #{title}: #{menu.priority} -> #{priority}"
    menu.update!(priority: priority) if apply
  end
  menu
end

briefe = folder(author, 'Briefe', 1, apply)
abhandlungen = folder(author, 'Abhandlungen', 2, apply)

[
  ['Sammlung der Briefe', 1, briefe],
  ['Brief an Fortunatus über die Ermahnung zum Martyrium', 13, briefe],
  ['Über die Nichtigkeit der Götzen', 3, abhandlungen],
  ['An Quirinus: Drei Bücher Schriftbeweise', 4, abhandlungen],
  ['Über das Lob des Martyriums', 14, abhandlungen],
].each do |title, priority, parent|
  next if parent.nil?

  menu = ::Menu.find_by(page_id: author.id, parent_id: parent.id, title: title)
  if menu.nil?
    puts "создать заготовку: #{title}"
    ::Menu.create!(page_id: author.id, parent_id: parent.id, title: title,
                   priority: priority, is_gold: false) if apply
  elsif menu.priority != priority
    puts "priority #{title}: #{menu.priority} -> #{priority}"
    menu.update!(priority: priority) if apply
  end
end

puts apply ? 'ПРИМЕНЕНО' : 'DRY RUN (APPLY=1 для записи)'
