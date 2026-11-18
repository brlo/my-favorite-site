# Второй проход разметки seo_kind - ручные решения, которые автоматика не осилила.
#
# 1. Снимает person с русских Вселенских Соборов: римские цифры в заголовке («VII Вселенский Собор»)
#    не ловятся фильтром года из первого прохода, а в подзаголовке цифры есть.
# 2. Ставит person авторам без цифр в подзаголовке (Варнава, Кодрат и т.п.). Список отобран вручную
#    по полному перечню страниц-списков без годов: всё остальное там - папки сайта, молитвословы, музыка.
#    person проставляется и переводам статьи (группа group_lang_id).
# 3. Ставит book цельным произведениям из меню авторов: >= 100К знаков, не часть («#3», «(old)»),
#    не том собрания сочинений («Часть», «Partie», «Tom»...). Переводы той же работы не трогаем:
#    в других языках та же работа может быть нарезана на части.
#
# Запуск: bin/rails runner script/seo/mark_seo_kinds_pass2.rb          - отчёт
#         APPLY=1 bin/rails runner script/seo/mark_seo_kinds_pass2.rb  - записать

COUNCIL_IDS = [642, 645, 646, 647, 648].freeze

# ru: Варнава, Кодрат, Аристид, Дмитрий Беляков, Авва Дорофей, Марк Подвижник,
#     Дионисий Ареопагит, Джон Уайтфорд; en: Aristides, Fr. John Whiteford;
# fr: Abba Dorothée; grc: Σεραπίων, Διονύσιος; la: Marcus Minucius Felix; zh-Hans: митр. Тихон
AUTHOR_IDS = [433, 435, 441, 959, 1216, 1220, 2556, 4561,
              5322, 4558, 1218, 926, 1507, 2557, 4291].freeze

CHUNK_RE = '\s#\d+\b|\(old\)'
VOLUME_RE = 'Часть|Partie|\bPart\b|\bTom\b|Volume|собрание сочинений'

councils = ::Page.where(id: COUNCIL_IDS, seo_kind: 'person')
puts "=== 1. Соборы, снимаю person: #{councils.count} ==="
councils.order(:id).each { |p| puts "#{p.id} | #{p.lang} | #{p.title}" }

authors = ::Page.where(id: AUTHOR_IDS)
puts "\n=== 2. Авторы без годов, ставлю person (плюс переводы): #{authors.count} ==="
authors.order(:lang, :id).each { |p| puts "#{p.id} | #{p.lang} | #{p.title}" }

# всё в памяти: два индексированных запроса вместо join по lower(path) в цикле
person_ids = ::Page.where(seo_kind: 'person').pluck(:id)
person_titles = ::Page.where(id: person_ids).pluck(:id, :title).to_h
ref_pairs = ::Menu.where(page_id: person_ids).pluck('lower(path)', 'page_id')
paths = ref_pairs.map(&:first).uniq
chunk_re = /\s#\d+\b|\(old\)/
volume_re = /#{VOLUME_RE}/i
books = ::Page.where(is_published: true, path_low: paths)
              .where("length(coalesce(body, '')) >= 100000")
              .filter_map do |p|
                next if p.title.match?(chunk_re) || p.title.match?(volume_re)

                refs = ref_pairs.select { |path, _pid| path == p.path_low }.map(&:last)
                [p, refs]
              end
books.sort_by! { |p, _| [p.lang, p.id] }

puts "\n=== 3. Книги из меню авторов (цельные работы >= 100К, не части и не тома): #{books.size} ==="
books.each do |p, refs|
  authors_of = refs.uniq.filter_map { person_titles[_1] }.uniq.first(2).join(' / ')
  puts "#{p.id} | #{p.lang} | #{(p.body.to_s.length / 1000)}К | #{p.title} | #{authors_of}"
end

if ENV['APPLY'] == '1'
  councils.update_all(seo_kind: nil) # rubocop:disable Rails/SkipsModelValidations
  authors.find_each do |p|
    p.update_column(:seo_kind, 'person') # rubocop:disable Rails/SkipsModelValidations
    ::Page.where(group_lang_id: p.group_lang_id).where.not(id: p.id).update_all(seo_kind: 'person') # rubocop:disable Rails/SkipsModelValidations
  end
  books.each { |p, _| p.update_column(:seo_kind, 'book') } # rubocop:disable Rails/SkipsModelValidations
  extra = ::Page.where(group_lang_id: authors.pluck(:group_lang_id).compact).where.not(id: AUTHOR_IDS)
  puts "\nЗаписано: person снят с #{councils.count}, авторы + переводы person: #{authors.count} + #{extra.count}, books: #{books.size}."
else
  puts "\nРежим отчёта. Для записи: APPLY=1 bin/rails runner script/seo/mark_seo_kinds_pass2.rb"
end
