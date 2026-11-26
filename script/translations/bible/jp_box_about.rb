# Публикует статью «О переводе» jp-box (ru) из HTML-источника в репозитории.
#
#   bin/rails runner script/translations/bible/jp_box_about.rb
#
# Текст статьи редактируется в db/translations/bible/jp-box/about_ru.html;
# скрипт только выкладывает его на страницу (страница должна существовать).
PATH = 'О_переводе_японской_Библии'
SRC = Rails.root.join('db/translations/bible/jp-box/about_ru.html')

body = File.read(SRC)
page = ::Page.find_by(lang: 'ru', path_low: PATH.downcase)
raise "нет страницы #{PATH}" unless page

page.update!(body: body)
puts "обновлено: ##{page.id} #{page.path} (#{page.body.length} знаков)"
