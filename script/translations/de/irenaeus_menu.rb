# frozen_string_literal: true

# Меню Иринея Лионского по русскому эталону: категории «Polemik»,
# «Katechese», «Verschiedenes»; пять книг — внутри «Gegen die Häresien».
#
#   bin/rails runner script/translations/de/irenaeus_menu.rb            # dry run
#   bin/rails runner script/translations/de/irenaeus_menu.rb APPLY=1    # запись

apply = ARGV.include?('APPLY=1')
author = ::Page.find_by!(lang: 'de', path: 'Irenaeus_von_Lyon')

def folder(author, title, priority, apply)
  menu = ::Menu.find_by(page_id: author.id, parent_id: nil, title: title)
  if menu.nil?
    puts "создать папку: #{title}"
    menu = ::Menu.create!(page_id: author.id, title: title, priority: priority) if apply
  elsif menu.priority != priority
    puts "папка #{title}: priority #{menu.priority} -> #{priority}"
    menu.update!(priority: priority) if apply
  end
  menu
end

def move_item(author, parent, title:, path:, priority:, is_gold:, apply:, exclude_id: nil)
  scope = ::Menu.where(page_id: author.id, path: path)
  scope = scope.where.not(id: exclude_id) if exclude_id
  menu = ::Menu.find_by(page_id: author.id, parent_id: parent&.id, path: path) ||
         scope.first
  if menu.nil?
    puts "создать: #{title} -> #{path} (parent #{parent&.title || 'root'})"
    return unless apply

    return ::Menu.create!(page_id: author.id, parent_id: parent&.id, title: title,
                          path: path, priority: priority, is_gold: is_gold)
  end
  attrs = { title: title, priority: priority, is_gold: is_gold }
  attrs[:parent_id] = parent&.id if parent && menu.parent_id != parent.id
  changed = attrs.reject { |k, v| menu.public_send(k) == v }
  unless changed.empty?
    puts "обновить: #{menu.title} -> #{title} (parent #{parent&.title || 'root'}, #{changed.keys.join(', ')})"
    menu.update!(changed) if apply
  end
  menu
end

if apply && ARGV.include?('RESET=1')
  removed = ::Menu.where(page_id: author.id).delete_all
  puts "удалено пунктов меню автора: #{removed}"
end

polemik = folder(author, 'Polemik', 1, apply)
katechese = folder(author, 'Katechese', 2, apply)
verschiedenes = folder(author, 'Verschiedenes', 3, apply)
if apply
  section = ::Menu.find_by(page_id: author.id, parent_id: polemik.id, path: 'Irenaeus_Gegen_die_Haeresien_1')
  if section.nil?
    puts 'создать: Entlarvung und Widerlegung … (Gegen die Häresien) -> Irenaeus_Gegen_die_Haeresien_1'
    section = ::Menu.create!(page_id: author.id, parent_id: polemik.id,
                             title: 'Entlarvung und Widerlegung der fälschlich sogenannten Gnosis (Gegen die Häresien)',
                             path: 'Irenaeus_Gegen_die_Haeresien_1', priority: 1, is_gold: false)
  else
    section.update!(title: 'Entlarvung und Widerlegung der fälschlich sogenannten Gnosis (Gegen die Häresien)',
                    priority: 1, is_gold: false) if section.title != 'Entlarvung und Widerlegung der fälschlich sogenannten Gnosis (Gegen die Häresien)'
  end

  (1..5).each do |n|
    move_item(author, section, title: "Buch #{n}", path: "Irenaeus_Gegen_die_Haeresien_#{n}",
              priority: n, is_gold: true, apply: apply, exclude_id: section.id)
  end

  move_item(author, katechese, title: 'Erweis der apostolischen Verkündigung',
            path: 'Irenaeus_Demonstratio', priority: 1, is_gold: false, apply: apply)

  frag = ::Menu.find_by(page_id: author.id, parent_id: verschiedenes.id, title: 'Fragmente')
  if frag.nil?
    puts 'создать: Fragmente (без ссылки)'
    ::Menu.create!(page_id: author.id, parent_id: verschiedenes.id,
                   title: 'Fragmente', priority: 1, is_gold: false)
  end
else
  puts 'создать: Entlarvung und Widerlegung … (Gegen die Häresien) -> Irenaeus_Gegen_die_Haeresien_1'
  (1..5).each { |n| puts "перенести: Irenaeus_Gegen_die_Haeresien_#{n} -> #{n}. Buch" }
  puts 'перенести: Irenaeus_Demonstratio -> Katechese'
  puts 'создать: Fragmente (без ссылки)'
end

puts apply ? 'ПРИМЕНЕНО' : 'DRY RUN (APPLY=1 для записи)'
