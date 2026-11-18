# Помечает страницы-авторы seo_kind='person' (для JSON-LD Person).
#
# Правило: страница-«список», опубликована, в подзаголовке есть годы (3-4 цифры),
# а в самом заголовке 3-4-значного года нет — Соборы всегда пишут год в заголовке
# («IV Вселенский Собор (451)»), поэтому на них правило не срабатывает.
#
# Запуск (в контейнере): bin/rails runner script/seo/backfill_seo_kind.rb        - только отчёт
#                         APPLY=1 bin/rails runner script/seo/backfill_seo_kind.rb - записать
#
# Отчёт также печатает: списки без годов (папки и авторы без цифр в подзаголовке) и
# большие статьи (кандидаты в книги) — их помечать руками в админке, там нужен человек.

LIST_TYPE = ::Page::PAGE_TYPES['список']
YEAR_RE = '\\d{3,4}'

lists = ::Page.where(page_type: LIST_TYPE, is_published: true)
candidates = lists.where('title_sub ~ ?', YEAR_RE).where.not('title ~ ?', YEAR_RE).order(:lang, :id)
councils = lists.where('title ~ ?', YEAR_RE).order(:lang, :id)
no_years = lists.where('title_sub IS NULL OR length(title_sub) = 0 OR title_sub !~ ?', YEAR_RE)
                .where.not('title ~ ?', YEAR_RE).order(:lang, :id)
book_candidates = ::Page.where(page_type: ::Page::PAGE_TYPES['статья'], is_published: true)
                        .where("length(coalesce(body, '')) > 150000").order(:lang, :id)

puts "=== Кандидаты в авторы (будет поставлено person): #{candidates.count} ==="
candidates.each { |p| puts "#{p.id} | #{p.lang} | #{p.title} | #{p.title_sub.to_s[0, 60]}" }

puts "\n=== Списки с годом в заголовке (Соборы и т.п. - не трогаем): #{councils.count} ==="
councils.each { |p| puts "#{p.id} | #{p.lang} | #{p.title}" }

puts "\n=== Списки без годов в подзаголовке (папки; пометить person вручную авторам без цифр): #{no_years.count} ==="
no_years.each { |p| puts "#{p.id} | #{p.lang} | #{p.title}" }

puts "\n=== Большие статьи >150К знаков (кандидаты в book - помечать вручную): всего #{book_candidates.count}, топ-25: ==="
book_candidates.order(Arel.sql('length(coalesce(body, \'\')) DESC')).limit(25)
              .each { |p| puts "#{p.id} | #{p.lang} | #{p.title} | #{p.body.to_s.length} зн." }

if ENV['APPLY'] == '1'
  candidates.find_each { |p| p.update_column(:seo_kind, 'person') } # rubocop:disable Rails/SkipsModelValidations
  puts "\nЗаписано person: #{candidates.count} страниц."
else
  puts "\nРежим отчёта. Для записи: APPLY=1 bin/rails runner script/seo/backfill_seo_kind.rb"
end
