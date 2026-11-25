# frozen_string_literal: true

# Проверка структуры святоотеческой библиотеки языка:
#   bin/rails runner script/translations/check_library_structure.rb de
#   bin/rails runner script/translations/check_library_structure.rb fr
#
# Ловит ровно те ошибки, из-за которых на странице автора не было трудов:
# - труд лежит непосредственно под списком раздела, а не под автором;
# - пункт труда висит в меню списка, а не в меню автора;
# - у автора нет своего меню (трудов).

LISTS = {
  'de' => 'Kirchenvaeter',
  'fr' => '4saQ_Ouvrages_des_anciens_chrétiens',
}.freeze

lang = ARGV.first || 'de'
list_path = LISTS[lang] or abort("нет списка для #{lang}")
list = ::Page.find_by(lang: lang, path: list_path) or abort("нет списка #{list_path}")

problems = []

def ru_parent_author?(page)
  ru = ::Page.find_by(lang: 'ru', group_lang_id: page.group_lang_id)
  return false unless ru&.parent_id

  parent = ::Page.find_by(id: ru.parent_id)
  parent && parent.page_type == 4 && parent.path != 'church_writers'
end

# 1. Труды, лежащие прямо под списком, хотя в RU они под автором.
direct_works = ::Page.where(lang: lang, parent_id: list.id, page_type: 1)
direct_works.find_each do |page|
  next unless ru_parent_author?(page)

  problems << "труд под списком: #{page.path} (parent_id=#{list.id}, в RU — под автором)"
end

# 2. Пункты меню списка, ведущие на труд, который в RU лежит под автором.
work_paths = ::Page.where(lang: lang, page_type: 1).pluck(:path)
::Menu.where(page_id: list.id, path: work_paths).find_each do |menu|
  page = ::Page.find_by(lang: lang, path: menu.path)
  next unless page && ru_parent_author?(page)

  problems << "пункт труда в меню списка: #{menu.title} -> #{menu.path}"
end

# 3. Авторы с трудами, но без своего меню.
::Page.where(lang: lang, parent_id: list.id, page_type: 4).find_each do |author|
  next if ::Page.where(parent_id: author.id, page_type: 1).none?

  problems << "у автора есть труды, но нет меню: #{author.path}" if ::Menu.where(page_id: author.id).none?
end

# 4. Дубли пунктов с одним путём в одной папке.
::Menu.where(page_id: list.id).where.not(path: [nil, '']).group_by { |m| [m.parent_id, m.path] }.each do |(parent_id, path), items|
  problems << "дубль пункта #{path} в папке #{parent_id}: #{items.map(&:id).join(', ')}" if items.size > 1
end

puts "#{lang}: авторов в списке #{::Page.where(lang: lang, parent_id: list.id, page_type: 4).count}, " \
     "трудов под авторами #{::Page.where(lang: lang, page_type: 1).where.not(parent_id: list.id).count}"
if problems.empty?
  puts 'структура в порядке'
else
  puts "проблем: #{problems.size}"
  problems.each { |p| puts "  - #{p}" }
  exit 1
end
