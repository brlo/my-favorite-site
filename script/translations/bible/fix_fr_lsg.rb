# Православные чтения, которых нет в базовом тексте модуля LSG 1910: возвращаем их
# в квадратных скобках (1 Ин 5:7 — свидетельство Отца, Слова и Святого Духа).
# Скрипт идемпотентен; после повторного импорта модуля его надо прогнать снова.
# bin/rails runner script/translations/bible/fix_fr_lsg.rb
FIXES = {
  %w[1in 5 7] => 'Car il y en a trois qui rendent témoignage [dans le ciel : le Père, le Verbe et le Saint-Esprit ; et ces trois sont un] :',
  %w[1tim 3 16] => 'Et, sans contredit, le mystère de la piété est grand: [Dieu] a été manifesté en chair, justifié par l’Esprit, vu des anges, prêché aux Gentils, cru dans le monde, élevé dans la gloire.',
  %w[act 20 28] => 'Prenez donc garde à vous-mêmes, et à tout le troupeau sur lequel le Saint-Esprit vous a établis évêques, pour paître l’Église du Seigneur [et de Dieu], qu’il s’est acquise par son propre sang.',
  %w[otkr 1 11] => 'qui disait: <j>Ce que tu vois, écris-le dans un livre, [je suis l’Alpha et l’Oméga, le premier et le dernier,] et envoie-le aux sept Églises, à Éphèse, à Smyrne, à Pergame, à Thyatire, à Sardes, à Philadelphie, et à Laodicée.</j>',
  %w[kol 1 14] => 'en qui nous avons la rédemption [par son sang], la rémission des péchés.',
  %w[1in 4 3] => 'et tout esprit qui ne confesse pas Jésus [Christ venu en chair] n’est pas de Dieu, c’est celui de l’antéchrist, dont vous avez appris la venue, et qui maintenant est déjà dans le monde.',
  %w[lk 2 33] => 'Son père [Joseph] et sa mère étaient dans l’admiration des choses qu’on disait de lui.',
  %w[1kor 15 47] => 'Le premier homme, tiré de la terre, est terrestre; le second homme [le Seigneur] est du ciel.',
  %w[ef 3 9] => 'et de mettre en lumière quelle est la dispensation du mystère caché de tout temps en Dieu qui a créé toutes choses [par Jésus-Christ],',
  %w[otkr 22 19] => 'et si quelqu’un retranche quelque chose des paroles du livre de cette prophétie, Dieu retranchera sa part de l’arbre [du livre] de la vie et de la ville sainte, décrits dans ce livre.',
}

san = Rails::Html::FullSanitizer.new
FIXES.each do |(book, chapter, line), t|
  v = Verse.find_by!(tr_code: 'fr-lsg', book: book, chapter: chapter, line: line)
  if v.text == t
    puts "#{book} #{chapter}:#{line} уже исправлено"
    next
  end
  search = san.sanitize(t).gsub("\u00AD", '')
  v.update!(text: t, text_search: search)
  Verse.where(id: v.id).update_all(
    Verse.sanitize_sql(["text_tsvector = to_tsvector(?, text_search)", LANG_TO_PG_LANGUAGE['fr'] || 'simple'])
  )
  puts "#{book} #{chapter}:#{line}: #{t[0, 70]}"
end
