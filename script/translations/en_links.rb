# Вкладки «Писание / Предание» для EN-раздела цитат: links у EN-страниц по RU-эталону.
#
#   bin/rails runner script/translations/en_links.rb [--dry]
#
# RU-страницы разделов q и q-saints имеют links вида
#   [["По Библии", "<path соседней статьи>"], ["По святым отцам", ""]]
# (пустой путь — текущая вкладка). Скрипт переносит их на EN-страницы:
#   * списки en-q / en-saints-q — вкладки «Scripture» / «Tradition»;
#   * статьи — «By Scripture» / «By the Fathers»;
#   * путь соседа ищется по group_lang_id (EN-пара RU-статьи); если EN-пары
#     ещё нет — ведём на список раздела (en-q / en-saints-q).
# Идемпотентен: повторный запуск обновляет только изменившиеся links.
# После импорта новой партии — запускать на dev и на проде.
# --check — ничего не пишет, выходит с кодом 1, если вкладки расходятся с RU.
require 'json'

dry = ARGV.include?('--dry')
check = ARGV.include?('--check')
list_paths = { 'en-q' => 'en-saints-q', 'en-saints-q' => 'en-q' }
bible_labels = ['По Библии', 'По Писанию', 'Писание']
father_labels = ['По святым отцам', 'Предание']
ru_by_group = Page.where(lang: 'ru').where.not(group_lang_id: nil).index_by(&:group_lang_id)
changed = 0
report = []

Page.where(lang: 'en').where.not(group_lang_id: nil).find_each do |p|
  r = ru_by_group[p.group_lang_id] or next
  next if r.links.blank?
  is_list = p.path_low == 'en-q' || p.path_low == 'en-saints-q'
  bible = r.links.find { |label, _| bible_labels.include?(label) }
  father = r.links.find { |label, _| father_labels.include?(label) }
  next unless bible || father

  build = lambda do |pair, label_short, label_long, fallback|
    label = is_list ? label_short : label_long
    path = pair && pair[1].to_s
    if path.blank?
      [label, '']
    else
      rp = Page.find_by(lang: 'ru', path: path)
      ep = rp && Page.find_by(lang: 'en', group_lang_id: rp.group_lang_id)
      [label, ep&.path || fallback]
    end
  end
  new_links = []
  new_links << build.(bible, 'Scripture', 'By Scripture', 'en-q') if bible
  new_links << build.(father, 'Tradition', 'By the Fathers', 'en-saints-q') if father
  next if p.links == new_links

  changed += 1
  report << [p.path, p.links, new_links]
  p.update!(links: new_links) unless dry || check
end
if check && changed.positive?
  puts "вкладки расходятся с RU: #{changed} страниц(ы); запусти без --check"
  report.first(15).each { |row| puts row.inspect }
  exit 1
end
puts "#{dry ? 'DRY ' : ''}changed: #{changed}"
report.first(15).each { |row| puts row.inspect } unless check
