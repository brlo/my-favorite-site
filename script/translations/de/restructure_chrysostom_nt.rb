# frozen_string_literal: true

# Группирует новозаветные труды Златоуста по библейским книгам, как в RU.
#   bin/rails runner script/translations/de/restructure_chrysostom_nt.rb [APPLY=1]

apply = ARGV.include?('APPLY=1')

NT_BOOKS = [
  { title: 'Homilien über den 1. Timotheusbrief', paths: ['Chrysostomus_1_Timotheus'] },
  { title: 'Homilien über den 2. Timotheusbrief', paths: ['Chrysostomus_2_Timotheus'] },
  { title: 'Homilien über den Titusbrief', paths: ['Chrysostomus_Titus'] },
  { title: 'Homilien über den Philemonbrief', paths: ['Chrysostomus_Philemon'] },
  { title: 'Homilien über den Hebräerbrief', paths: %w[Chrysostomus_Hebraeerbrief_1 Chrysostomus_Hebraeerbrief_2] },
  { title: 'Homilien über das Matthäusevangelium', paths: %w[Chrysostomus_Matthaeus_1 Chrysostomus_Matthaeus_2 Chrysostomus_Matthaeus_3 Chrysostomus_Matthaeus_4 Chrysostomus_Matthaeus_5 Chrysostomus_Matthaeus_6] },
  { title: 'Homilien über den Römerbrief', paths: %w[Chrysostomus_Roemerbrief_1 Chrysostomus_Roemerbrief_2 Chrysostomus_Roemerbrief_3] },
  { title: 'Homilien über den 1. Korintherbrief', paths: %w[Chrysostomus_1_Korinther_1 Chrysostomus_1_Korinther_2 Chrysostomus_1_Korinther_3] },
  { title: 'Homilien über den 2. Korintherbrief', paths: %w[Chrysostomus_2_Korinther_1 Chrysostomus_2_Korinther_2] },
  { title: 'Kommentar zum Galaterbrief', paths: ['Chrysostomus_Galaterbrief'] },
  { title: 'Homilien über den Philipperbrief', paths: ['Chrysostomus_Philipperbrief'] },
  { title: 'Homilien über den Kolosserbrief', paths: ['Chrysostomus_Kolosserbrief'] },
  { title: 'Homilien über den Epheserbrief', paths: %w[Chrysostomus_Epheserbrief_1 Chrysostomus_Epheserbrief_2] },
  { title: 'Homilien über den 1. Thessalonicherbrief', paths: ['Chrysostomus_1_Thessalonicher'] },
  { title: 'Homilien über den 2. Thessalonicherbrief', paths: ['Chrysostomus_2_Thessalonicher'] },
].freeze

de_author = ::Page.find_by!(lang: 'de', path: 'Johannes_Chrysostomus')
category = ::Menu.find_by!(page_id: de_author.id, parent_id: nil, title: 'Neutestamentliche Kommentare')

NT_BOOKS.each_with_index do |book, index|
  parts = book[:paths].filter_map { |path| ::Menu.find_by(page_id: de_author.id, path: path) }
  next if parts.empty?

  if parts.size == 1
    item = parts.first
    puts "#{book[:title]}: одиночный пункт"
    item.update!(parent_id: category.id, title: book[:title], priority: index) if apply
    next
  end

  parent = ::Menu.find_by(page_id: de_author.id, parent_id: category.id, title: book[:title])
  if parent.nil?
    puts "создать группу: #{book[:title]}"
    parent = ::Menu.create!(page_id: de_author.id, parent_id: category.id, title: book[:title],
                            path: book[:paths].first, priority: index) if apply
  elsif apply
    parent.update!(path: book[:paths].first, priority: index)
  end
  next unless apply

  parts.each_with_index do |part, i|
    part.update!(parent_id: parent.id, title: (i + 1).to_s, priority: i + 1)
  end
end

puts apply ? 'ПРИМЕНЕНО' : 'DRY RUN (APPLY=1 для записи)'
