# frozen_string_literal: true

# Оставляет в меню Иоанна Златоуста только французскую часть названия.
#   bin/rails runner script/translations/fr/fix_chrysostom_menu.rb [APPLY=1]

apply = ARGV.include?('APPLY=1')
page = ::Page.find_by!(lang: 'fr', path: '56Vd_Jean_Chrysostome_IVe_siècle')

::Menu.where(page_id: page.id).find_each do |item|
  title = item.title.to_s.split(' / ').first.strip
  title = title.sub(/\s*\([^)]*[А-Яа-яЁё][^)]*\)\s*\z/, '').strip
  next if title == item.title

  puts "#{item.title} -> #{title}"
  item.update!(title: title) if apply
end

puts apply ? 'ПРИМЕНЕНО' : 'DRY RUN (APPLY=1 для записи)'
