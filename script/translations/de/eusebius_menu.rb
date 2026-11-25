# frozen_string_literal: true

# Меню Евсевия по RU: «Geschichte» → «Kirchengeschichte» (книги 1–10),
# заготовки «Chronik» и «Leben des Kaisers Konstantin».
#   bin/rails runner script/translations/de/eusebius_menu.rb [APPLY=1]

apply = ARGV.include?('APPLY=1')
author = ::Page.find_by!(lang: 'de', path: 'Eusebius_von_Cäsarea')

def folder(author, title, priority, apply)
  menu = ::Menu.find_by(page_id: author.id, parent_id: nil, title: title)
  if menu.nil?
    puts "создать папку: #{title}"
    menu = ::Menu.create!(page_id: author.id, title: title, priority: priority) if apply
  elsif menu.priority != priority
    menu.update!(priority: priority) if apply
  end
  menu
end

geschichte = folder(author, 'Geschichte', 1, apply)

if apply
  section = ::Menu.find_by(page_id: author.id, parent_id: geschichte.id, path: 'Eusebius_Kirchengeschichte_1')
  if section.nil?
    puts 'создать: Kirchengeschichte (раздел)'
    section = ::Menu.create!(page_id: author.id, parent_id: geschichte.id,
                             title: 'Kirchengeschichte', path: 'Eusebius_Kirchengeschichte_1',
                             priority: 1, is_gold: false)
  elsif section.title != 'Kirchengeschichte' || section.priority != 1
    puts "раздел: #{section.title} -> Kirchengeschichte"
    section.update!(title: 'Kirchengeschichte', priority: 1, is_gold: false)
  end

  first = ::Menu.find_by(page_id: author.id, parent_id: section.id, title: 'Buch 1')
  if first.nil?
    puts 'создать: Buch 1 (внутри раздела)'
    ::Menu.create!(page_id: author.id, parent_id: section.id, title: 'Buch 1',
                   path: 'Eusebius_Kirchengeschichte_1', priority: 1, is_gold: false)
  end

  (2..10).each do |n|
    path = "Eusebius_Kirchengeschichte_#{n}"
    item = ::Menu.where(page_id: author.id, path: path).where.not(id: section.id).first
    next if item.nil?

    attrs = { parent_id: section.id, title: "Buch #{n}", priority: n, is_gold: false }
    changed = attrs.reject { |k, v| item.public_send(k) == v }
    unless changed.empty?
      puts "обновить: #{item.title} -> Buch #{n}"
      item.update!(changed)
    end
  end

  [['Chronik', 10], ['Leben des Kaisers Konstantin', 11]].each do |title, priority|
    next if ::Menu.exists?(page_id: author.id, parent_id: geschichte.id, title: title)

    puts "создать заготовку: #{title}"
    ::Menu.create!(page_id: author.id, parent_id: geschichte.id, title: title,
                   priority: priority, is_gold: false)
  end
else
  puts 'создать раздел Kirchengeschichte, перенести книги 1–10, добавить Chronik/Konstantin'
end

puts apply ? 'ПРИМЕНЕНО' : 'DRY RUN (APPLY=1 для записи)'
