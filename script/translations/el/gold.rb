# Переносит золотые пункты меню (is_gold) с RU-эталона на el-переводы.
#   bin/rails runner script/translations/el/gold.rb [--dry]
# Ищет RU-пункт меню с is_gold, находит перевод по group_lang_id и ставит
# is_gold соответствующему пункту меню el-q. Папки без path пропускает.
dry = ARGV.include?('--dry')
ru_q = Page.find_by(lang: 'ru', path: 'q')
el_q = Page.find_by(lang: 'el', path: 'el-q')
abort 'нет q / el-q' unless ru_q && el_q
changed = 0
report = []
Menu.where(page_id: ru_q.id, is_gold: true).find_each do |m|
  next if m.path.blank?
  rp = Page.where(lang: 'ru', path: m.path).select(:id, :group_lang_id).first
  next unless rp&.group_lang_id
  ep = Page.where(lang: 'el', group_lang_id: rp.group_lang_id).select(:id, :path).first
  next unless ep
  em = Menu.where(page_id: el_q.id, path: ep.path).first
  next unless em
  next if em.is_gold
  changed += 1
  report << [m.title, m.path, ep.path]
  em.update!(is_gold: true) unless dry
end
puts "#{dry ? 'DRY ' : ''}золотых: #{changed}"
report.each { |row| puts row.inspect }
