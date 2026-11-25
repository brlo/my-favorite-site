# frozen_string_literal: true

# Зеркалирование «золотых» пунктов меню (menus.is_gold) с русского эталона на
# переводы по group_lang_id. Работает и для цитатников, и для библиотеки:
# берёт русские пункты с path, находит страницу перевода той же группы и
# ставит is_gold её пунктам меню (и в меню списка, и в меню автора).
#
#   bin/rails runner script/translations/gold.rb de [--dry]
#   bin/rails runner script/translations/gold.rb fr
#   bin/rails runner script/translations/gold.rb el --dry   # цитатник el-q
#
# Если у одного path в RU разные is_gold (например, раздел «Против ересей» и
# первая книга имеют один path), такие пункты пропускаются: их структуру
# выставляет профильный скрипт.

lang = ARGV.find { |arg| !arg.start_with?('--') } || 'el'
dry = ARGV.include?('--dry')

ru_pages = ::Page.where(lang: 'ru').pluck(:path, :group_lang_id).to_h
tr_paths = ::Page.where(lang: lang).where.not(group_lang_id: [nil, ''])
                 .pluck(:group_lang_id, :path).to_h

ru_gold = Hash.new { |h, k| h[k] = [] }
::Menu.where.not(path: [nil, '']).find_each { |m| ru_gold[m.path] << m.is_gold }
ambiguous = ru_gold.select { |_path, values| values.uniq.size > 1 }.keys

changed = 0
report = []
ru_gold.each do |path, values|
  next if values.uniq.size > 1

  group = ru_pages[path]
  next if group.blank?

  tr_path = tr_paths[group]
  next if tr_path.blank?

  ::Menu.where(path: tr_path).find_each do |tr_menu|
    next if tr_menu.is_gold == values.first

    changed += 1
    report << [path, tr_menu.path, values.first] if report.size < 100
    tr_menu.update!(is_gold: values.first) unless dry
  end
end

puts "#{dry ? 'DRY RUN ' : ''}золотых изменено: #{changed}"
puts "пропущены неоднозначные path: #{ambiguous.join(', ')}" if ambiguous.any?
report.each { |row| puts row.inspect }
