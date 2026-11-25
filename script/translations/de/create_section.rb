# frozen_string_literal: true

# Создаёт немецкий раздел святоотеческой библиотеки: страницу-список `Kirchenvaeter`
# в языковой группе русского `church_writers`, заполняет пункт меню links_de
# и заводит папки веков. Скрипт идемпотентен.
#
#   bin/rails runner script/translations/de/create_section.rb
#
# После него — импорт партии:
#   bin/rails pages:import_translations FILE=db/translations/de/kl_00.yml PUBLISH=1

lang = 'de'
list_path = 'Kirchenvaeter'

links = ::Page.find_by!(lang: lang, path: 'links_de')
original = ::Page.find_by!(lang: 'ru', path: 'church_writers')
list = ::Page.find_by(lang: lang, path: list_path)

if list
  puts "страница уже есть: #{list.path} (id #{list.id})"
else
  body = ::File.read(::Rails.root.join('script/translations/de/section_intro.html'))
  list = ::Page.create!(
    lang: lang,
    path: list_path,
    title: 'Werke der alten heiligen Väter und Kirchenlehrer',
    title_sub: 'Bibliothek der Kirchenväter in deutscher Übersetzung',
    meta_desc: 'Werke der alten heiligen Väter und Kirchenlehrer auf Deutsch: Klemens von Rom, Ignatius von Antiochien, Polykarp von Smyrna und andere Texte der alten Kirche.',
    body: body,
    page_type: 4,
    parent_id: links.id,
    group_lang_id: original.group_lang_id,
    is_published: true,
    edit_mode: original.edit_mode,
    user_id: original.user_id,
  )
  puts "создана страница: #{list.path} (id #{list.id})"
end

menu = ::Menu.find_by(page_id: links.id, title: '📚 Schriften der alten Christen')
if menu.nil?
  puts 'ВНИМАНИЕ: не найден пункт меню «📚 Schriften der alten Christen»'
elsif menu.path != list.path
  menu.update!(path: list.path)
  puts "пункт меню обновлён: #{menu.title} -> #{list.path}"
else
  puts "пункт меню уже ведёт на #{list.path}"
end

[['1. Jahrhundert', 1], ['2. Jahrhundert', 2]].each do |title, priority|
  if ::Menu.exists?(page_id: list.id, parent_id: nil, title: title)
    puts "папка уже есть: #{title}"
  else
    ::Menu.create!(page_id: list.id, parent_id: nil, title: title, priority: priority)
    puts "создана папка: #{title}"
  end
end

# seo_kind авторов — как у русских страниц (запускать после импорта партии)
{ 'Klemens_von_Rom' => 'person', 'Ignatius_von_Antiochien' => 'person',
  'Polykarp_von_Smyrna' => 'person' }.each do |path, kind|
  page = ::Page.find_by(lang: lang, path: path)
  next unless page
  next if page.seo_kind == kind

  page.update!(seo_kind: kind)
  puts "seo_kind: #{path} -> #{kind}"
end

puts
puts "меню #{list.path}:"
::Menu.where(page_id: list.id).order(:parent_id, :priority).each do |item|
  indent = item.parent_id ? '  ' : ''
  puts "#{indent}#{item.priority}. #{item.title} -> #{item.path || '(без ссылки)'}"
end
