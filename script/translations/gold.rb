# frozen_string_literal: true

# Зеркалирование «золотых» пунктов меню (menus.is_gold) с русского эталона на
# переводы по group_lang_id. Работает и для цитатников, и для библиотеки:
# берёт все русские пункты с path, находит страницу перевода той же группы и
# ставит is_gold её пунктам меню (и в меню списка, и в меню автора).
#
#   bin/rails runner script/translations/gold.rb de [--dry]
#   bin/rails runner script/translations/gold.rb fr
#   bin/rails runner script/translations/gold.rb el --dry   # цитатник el-q
#
# Без LANG — el (совместимость со старым el/gold.rb). Папки без path пропускает.

lang = ARGV.find { |arg| !arg.start_with?('--') } || 'el'
dry = ARGV.include?('--dry')

ru_pages = ::Page.where(lang: 'ru').pluck(:path, :group_lang_id).to_h
tr_paths = ::Page.where(lang: lang).where.not(group_lang_id: [nil, ''])
                 .pluck(:group_lang_id, :path).to_h

changed = 0
report = []
::Menu.where.not(path: [nil, '']).find_each do |ru_menu|
  group = ru_pages[ru_menu.path]
  next if group.blank?

  tr_path = tr_paths[group]
  next if tr_path.blank?

  ::Menu.where(path: tr_path).find_each do |tr_menu|
    next if tr_menu.is_gold == ru_menu.is_gold

    changed += 1
    report << [ru_menu.path, tr_menu.path, ru_menu.is_gold] if report.size < 100
    tr_menu.update!(is_gold: ru_menu.is_gold) unless dry
  end
end

puts "#{dry ? 'DRY RUN ' : ''}золотых изменено: #{changed}"
report.each { |row| puts row.inspect }
