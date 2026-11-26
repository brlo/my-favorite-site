# frozen_string_literal: true

# Группирует многочастные труды (Кассиан, Августин), как в RU.
#   bin/rails runner script/translations/de/group_author_parts.rb [APPLY=1]

apply = ARGV.include?('APPLY=1')

GROUPS = [
  ['Johannes_Cassianus', 'Unterredungen mit den Vätern', 'Vierundzwanzig Unterredungen mit den Vätern',
   %w[Cassian_Unterredungen_1 Cassian_Unterredungen_2]],
  ['Augustinus_von_Hippo', 'Autobiographische Werke', 'Bekenntnisse',
   %w[Augustinus_Bekenntnisse_1 Augustinus_Bekenntnisse_2]],
].freeze

GROUPS.each do |author_path, category_title, parent_title, paths|
  author = ::Page.find_by(lang: 'de', path: author_path)
  next if author.nil?

  category = ::Menu.find_by(page_id: author.id, parent_id: nil, title: category_title)
  next if category.nil?

  parts = paths.filter_map { |p| ::Menu.find_by(page_id: author.id, path: p) }
  next if parts.size < 2

  parent = ::Menu.find_by(page_id: author.id, parent_id: category.id, title: parent_title)
  if parent.nil?
    puts "создать группу: #{parent_title}"
    parent = ::Menu.create!(page_id: author.id, parent_id: category.id, title: parent_title,
                            path: paths.first, priority: 1) if apply
  end
  next unless apply

  parts.each_with_index do |part, i|
    part.update!(parent_id: parent.id, title: (i + 1).to_s, priority: i + 1)
  end
end

puts apply ? 'ПРИМЕНЕНО' : 'DRY RUN (APPLY=1 для записи)'
