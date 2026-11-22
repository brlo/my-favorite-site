# 1 Ин 5:7: в модуле LSG 1910 стих обрезан до «Car il y en a trois qui rendent témoignage:» —
# возвращаем свидетельство Отца, Слова и Святого Духа в квадратных скобках (как чтение,
# которого нет в базовом тексте Сегона, но которое цитируют древнейшие христиане).
# bin/rails runner script/translations/bible/fix_fr_lsg.rb
v = Verse.find_by!(tr_code: 'fr-lsg', book: '1in', chapter: 5, line: 7)
t = 'Car il y en a trois qui rendent témoignage [dans le ciel : le Père, le Verbe et le Saint-Esprit ; et ces trois sont un] :'
if v.text == t
  puts('уже исправлено')
else
  san = Rails::Html::FullSanitizer.new
  search = san.sanitize(t).gsub("\u00AD", '')
  v.update!(text: t, text_search: search)
  Verse.where(id: v.id).update_all(
    Verse.sanitize_sql(["text_tsvector = to_tsvector(?, text_search)", LANG_TO_PG_LANGUAGE['fr'] || 'simple'])
  )
  puts v.reload.text
end
