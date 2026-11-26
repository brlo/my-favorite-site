# frozen_string_literal: true

# Импорт работ, для которых нет RU-страницы: страница создаётся напрямую
# из заранее собранного HTML (BKV), с меню и ссылкой на источник.
#   bin/rails runner script/translations/de/import_external_works.rb [APPLY=1]

apply = ARGV.include?('APPLY=1')

WORKS = [
  {
    parent: 'Hilarius_von_Poitiers', category: 'Exegetische Werke',
    path: 'Hilarius_Matthaeuskommentar', title: 'Kommentar zum Matthäusevangelium',
    body: 'db/translations/de/external/hil_mat.html', priority: 1,
    source: ['Kommentar zum Matthäusevangelium', 'https://bkv.unifr.ch/de/works/cpl-430/versions/kommentar-zum-evangelium-des-matthaus-bkv'],
  },
  {
    parent: 'Cyrill_von_Alexandrien', category: 'Dogmatisch-polemische Werke',
    path: 'Cyrill_Alexandrien_Sieben_Gespraeche', title: 'Sieben Gespräche über die heilige und wesensgleiche Dreieinigkeit',
    body: 'db/translations/de/external/cyr_dial.html', priority: 6,
    source: ['Sieben Gespräche über die heilige und wesensgleiche Dreieinigkeit', 'https://bkv.unifr.ch/de/works/-42x/versions/sieben-gesprache-uber-die-heilige-und-wesensgleiche-dreieinigkeit-bkv'],
  },
  {
    parent: 'Eusebius_von_Cäsarea', category: 'Geschichte',
    path: 'Eusebius_Vita_Constantini', title: 'Vier Bücher über das Leben des Kaisers Konstantin',
    body: 'db/translations/de/external/eus_vita.html', priority: 11,
    source: ['Vier Bücher über das Leben des Kaisers Konstantin', 'https://bkv.unifr.ch/de/works/cpg-3496/versions/vier-bucher-uber-das-leben-des-kaisers-konstantin-und-des-kaisers-konstantin-rede-an-die-versammlung-der-heiligen-bkv'],
  },
].freeze

WORKS.each do |item|
  author = ::Page.find_by(lang: 'de', path: item[:parent])
  if author.nil?
    puts "нет автора: #{item[:parent]}"
    next
  end
  category = ::Menu.find_by(page_id: author.id, parent_id: nil, title: item[:category])
  if category.nil?
    puts "нет категории: #{item[:category]}"
    next
  end
  next unless apply

  title, url = item[:source]
  references = "<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>#{title}</em> " \
               "(Bibliothek der Kirchenväter). Text nach <a href=\"#{url}\">bkv.unifr.ch</a>; " \
               'die Anmerkungen der Ausgabe sind weggelassen.</p>'
  body = "<p><em>#{title} (Bibliothek der Kirchenväter).</em></p>" + File.read(item[:body], encoding: 'utf-8')

  page = ::Page.find_by(lang: 'de', path: item[:path])
  if page
    page.update!(title: item[:title], body: body, references: references, is_published: true)
    puts "обновлено: #{item[:path]}"
  else
    page = ::Page.create!(
      lang: 'de', parent_id: author.id, path: item[:path], title: item[:title],
      body: body, references: references, page_type: 1, is_published: true,
      edit_mode: author.edit_mode, user_id: author.user_id,
    )
    puts "создано: #{item[:path]}"
  end

  menu = ::Menu.find_by(page_id: author.id, path: page.path)
  if menu
    menu.update!(parent_id: category.id, title: item[:title], priority: item[:priority])
  else
    ::Menu.create!(page_id: author.id, parent_id: category.id, path: page.path,
                   title: item[:title], priority: item[:priority])
  end
end

puts apply ? 'ПРИМЕНЕНО' : 'DRY RUN (APPLY=1 для записи)'
