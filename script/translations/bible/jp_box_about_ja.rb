# Публикует японскую статью «О переводе» jp-box из HTML-источника в репозитории.
#
#   bin/rails runner script/translations/bible/jp_box_about_ja.rb
#
# Текст статьи редактируется в db/translations/bible/jp-box/about_ja.html;
# скрипт только выкладывает его на страницу (страница должна существовать).
PATH_JA = 'ビブレオックス訳について'
SRC = Rails.root.join('db/translations/bible/jp-box/about_ja.html')

body = File.read(SRC)
page = ::Page.find_by(lang: 'ja', path_low: PATH_JA.downcase)
raise "нет страницы #{PATH_JA}" unless page

page.update!(body: body)
puts "обновлено: ##{page.id} #{page.path} (#{page.body.length} знаков)"
