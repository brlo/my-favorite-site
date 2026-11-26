# frozen_string_literal: true

# Группирует части книг Тертуллиана (Marcion, Ornement) под их книгами.
#   bin/rails runner script/translations/fr/fix_tertullian_menu.rb [APPLY=1]

apply = ARGV.include?('APPLY=1')
page = ::Page.find_by!(lang: 'fr', path: 'Trll_Tertullien_IIe_IIIe_siècle')

GROUPS = [
  {
    category: 'Semi-montanisme (207-212)',
    title: 'Contre Marcion',
    paths: %w[Trll_Contre_Marcion_1 Trll_Contre_Marcion_2 Trll_Contre_Marcion_3 Trll_Contre_Marcion_4 Trll_Contre_Marcion_5],
    priority: 8,
    labels: ['Livre I', 'Livre II', 'Livre III', 'Livre IV', 'Livre V'],
  },
  {
    category: 'Période de création ecclésiastique (~196-206)',
    title: 'De l’Ornement des Femmes',
    paths: %w[Trll_De_lOrnement_des_Femmes_1 Trll_De_lOrnement_des_Femmes_2],
    priority: 14,
    labels: ['Livre I', 'Livre II'],
  },
].freeze

GROUPS.each do |group|
  category = ::Menu.find_by!(page_id: page.id, parent_id: nil, title: group[:category])
  parent = ::Menu.find_by(page_id: page.id, parent_id: category.id, title: group[:title])
  if parent.nil?
    puts "создать книгу: #{group[:title]}"
    parent = ::Menu.create!(page_id: page.id, parent_id: category.id, title: group[:title],
                            path: group[:paths].first, priority: group[:priority]) if apply
  elsif apply
    parent.update!(path: group[:paths].first, priority: group[:priority])
  end
  next unless apply

  group[:paths].each_with_index do |path, i|
    item = ::Menu.find_by(page_id: page.id, path: path)
    next if item.nil?

    item.update!(parent_id: parent.id, title: group[:labels][i], priority: i + 1)
  end
end

puts apply ? 'ПРИМЕНЕНО' : 'DRY RUN (APPLY=1 для записи)'
