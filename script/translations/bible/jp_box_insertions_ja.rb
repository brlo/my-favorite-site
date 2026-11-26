# Публикует японский перевод статьи «Проблема вставок в Новом Завете».
#
#   bin/rails runner script/translations/bible/jp_box_insertions_ja.rb
#
# Источник — db/translations/bible/jp-box/insertions_ja.html.
PATH_JA = '新約聖書の挿入句の問題'
SRC = Rails.root.join('db/translations/bible/jp-box/insertions_ja.html')

body = File.read(SRC)
page = ::Page.find_by(lang: 'ja', path_low: PATH_JA.downcase)
atoms = {
  title: '新約聖書の挿入句の問題',
  meta_desc: '新約聖書の「挿入句」とされる箇所（マルコ16:9–20、ヨハネ7:53–8:11、Ⅰヨハネ5:7 など）をめぐる批判への回答。',
  body: body, page_type: 1, edit_mode: 1, is_published: true, is_bibleox: true
}
if page
  page.update!(atoms)
  puts "обновлено: ##{page.id} #{page.path} (#{page.body.length} знаков)"
else
  about = ::Page.find_by(lang: 'ja', path_low: 'ビブレオックス訳について'.downcase)
  page = ::Page.create!(atoms.merge(
    lang: 'ja', path: PATH_JA, parent_id: about&.parent_id, user_id: 1,
    group_lang_id: SecureRandom.hex(12)
  ))
  puts "создано: ##{page.id} #{page.path} (#{page.body.length} знаков)"
end
