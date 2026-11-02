# Восстанавливает стихи, которые старый MybibleImporter.clean стёр и пропустил (конец отрывка в скобках: Мк 16:20, Ин 5:4, Ин 8:11).
# bin/rails runner tmp/fix_brackets.rb [tmp/bibles/NRKV.SQLite3]
db = SQLite3::Database.new(ARGV[0] || 'tmp/bibles/NRKV.SQLite3', readonly: true)
san = Rails::Html::FullSanitizer.new
{ [480, 16, 20] => 'mk', [500, 5, 4] => 'in', [500, 8, 11] => 'in' }.each do |(b, c, l), book|
  orig = db.get_first_value('select text from verses where book_number=? and chapter=? and verse=?', [b, c, l])
  text = MybibleImporter.clean(orig)
  next puts("#{book} #{c}:#{l} уже есть") if Verse.exists?(tr_code: 'ko-nkrv', book: book, chapter: c, line: l)
  base = Verse.find_by!(tr_code: 'ko-nkrv', book: book, chapter: c, line: l - 1)
  v = Verse.create!(tr_code: base.tr_code, lang: base.lang, book_id: base.book_id, book: book, zavet: base.zavet,
                    chapter: c, line: l, address: "#{book}:#{c}:#{l}", text: text,
                    text_search: san.sanitize(text).gsub("­", ''), data: { 'orig' => orig })
  Verse.where(id: v.id).update_all(Verse.sanitize_sql(["text_tsvector = to_tsvector(?, text_search)", LANG_TO_PG_LANGUAGE['ko'] || 'simple']))
  puts "#{book} #{c}:#{l} добавлен: #{text[0, 50]}"
end
