# Публикует статью-словарь jp-box (ru) из файла в репозитории.
#
#   bin/rails runner script/translations/bible/jp_box_dictionary.rb
#
# Источник — db/translations/bible/jp-box/dictionary_ru.html (HTML статьи).
# Страница ищется по path_low; если её нет — создаётся в разделе, где лежит
# статья «О переводе» (тот же parent_id).
PATH = 'Словарь_японского_перевода_Библии'
SRC = Rails.root.join('db/translations/bible/jp-box/dictionary_ru.html')
body = File.read(SRC)

page = ::Page.find_by(lang: 'ru', path_low: PATH.downcase)
atoms = {
  title: 'Словарь японского перевода Библии',
  meta_desc: 'Словарь терминов японского перевода Библии jp-box: греческое слово, ' \
             'японское написание, объяснение и пример из перевода.',
  body: body,
  page_type: 1,
  edit_mode: 1,
  is_published: true,
  is_bibleox: true
}
if page
  page.update!(atoms)
  puts "обновлено: #{page.id} #{page.path}"
else
  about = ::Page.find_by(lang: 'ru', path_low: 'о_переводе_японской_библии')
  page = ::Page.create!(atoms.merge(
    lang: 'ru', path: PATH, parent_id: about&.parent_id, user_id: 1,
    group_lang_id: SecureRandom.hex(12)
  ))
  puts "создано: #{page.id} #{page.path}"
end
puts "body #{page.body.length}, rendered #{page.body_rendered.to_s.length}"
