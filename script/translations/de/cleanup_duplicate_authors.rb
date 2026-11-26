# frozen_string_literal: true

# Убирает из списка авторов заготовки, для которых уже есть настоящая страница.
#   bin/rails runner script/translations/de/cleanup_duplicate_authors.rb [APPLY=1]

apply = ARGV.include?('APPLY=1')

PAIRS = {
  'Aurelius Augustinus, seliger (354–430)' => 'Augustinus_von_Hippo',
  'Ephräm der Syrer, ehrwürdiger (~306–373)' => 'Ephraem_der_Syrer',
  'Epiphanius von Zypern, Heiliger (~315–403)' => 'Epiphanius_von_Salamis',
  'Hieronymus von Stridon, ehrwürdiger, seliger (~347–419)' => 'Hieronymus',
  'Johannes Cassian der Römer, ehrwürdiger (4.–5. Jh.)' => 'Johannes_Cassianus',
  'Johannes Chrysostomus, Heiliger (~347–407)' => 'Johannes_Chrysostomus',
}.freeze

list = ::Page.find_by!(lang: 'de', path: 'Kirchenvaeter')
PAIRS.each do |placeholder, real_path|
  next unless ::Page.exists?(lang: 'de', path: real_path)

  items = ::Menu.where(page_id: list.id, title: placeholder, path: [nil, ''])
  next if items.none?

  puts "удалить заготовку: #{placeholder} (#{items.count})"
  items.delete_all if apply
end

puts apply ? 'ПРИМЕНЕНО' : 'DRY RUN (APPLY=1 для записи)'
