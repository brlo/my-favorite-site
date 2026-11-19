# Вкладки-переключатели («Писание / Предание» и дополнительные) для EN-страниц по RU-эталону.
#
#   bin/rails runner script/translations/en_links.rb [--dry|--check]
#
# На RU-страницах Page#links хранит пары [подпись, path], пустой path — текущая вкладка,
# например у статьи о храме:
#   [["По Библии", "7PyK_Христианский_храм"], ["По святым отцам", "Христианские_храмы"],
#    ["Древние храмы", ""]]
# Из них pages/_chapters.html.erb рисует #links-sub. Импортер YAML links не переносит,
# поэтому после импорта партии нужен этот проход.
#
# Правила:
#   * списки en-q / en-saints-q — вкладки «Scripture» / «Tradition»;
#   * статьи — «By Scripture» / «By the Fathers»;
#   * дополнительные вкладки (3-я, 4-я — «Древние храмы», «Евхаристия в воскресенье» и т. п.)
#     сохраняются в том же порядке с переводом подписи (словарь LABELS) или, если подписи нет
#     в словаре, берётся заголовок EN-страницы;
#   * путь соседа ищется по group_lang_id (EN-пара RU-страницы). Если EN-перевода ещё нет:
#     для двух основных вкладок ведём на список раздела (en-q / en-saints-q), дополнительную
#     вкладку пропускаем (ссылки в links — только внутри своего языка);
#   * --check — ничего не пишет, выходит с кодом 1, если вкладки расходятся с RU.
# Идемпотентен. Запускать на dev и на проде после каждой партии.
bible_labels = ['По Библии', 'По Писанию', 'Писание']
father_labels = ['По святым отцам', 'Предание']
LABELS = {
  'По Библии' => 'By Scripture', 'По Писанию' => 'By Scripture', 'Писание' => 'Scripture',
  'По святым отцам' => 'By the Fathers', 'Предание' => 'Tradition',
  'Древние храмы' => 'Ancient temples',
  'Древние иконы' => 'Ancient icons',
  'Евхаристия в воскресенье' => 'The Eucharist on Sunday',
  'Указ имп. Константина' => 'Edict of Emperor Constantine',
  'Святыня' => 'Sacred things',
  'Благодать' => 'Grace',
  'Согласие отцов' => 'Consent of the Fathers',
  'Все цитаты о Евхаристии' => 'All quotes on the Eucharist',
  'История слова в мире' => 'History of the word in the world',
  'История слова на Руси' => 'History of the word in Rus',
  'PDF' => 'PDF'
}.freeze

dry = ARGV.include?('--dry')
check = ARGV.include?('--check')
ru_by_group = Page.where(lang: 'ru').where.not(group_lang_id: nil).index_by(&:group_lang_id)
changed = 0
report = []

Page.where(lang: 'en').where.not(group_lang_id: nil).find_each do |p|
  r = ru_by_group[p.group_lang_id] or next
  next if r.links.blank?
  is_list = %w[en-q en-saints-q].include?(p.path_low)
  new_links = []
  r.links.each do |orig, path|
    is_bible = bible_labels.include?(orig)
    is_father = father_labels.include?(orig)
    label = if is_list
              is_bible ? 'Scripture' : (is_father ? 'Tradition' : (LABELS[orig] || orig))
            else
              LABELS[orig] || orig
            end
    if path.blank?
      new_links << [LABELS[orig] || p.title, '']
      next
    end
    rp = Page.find_by(lang: 'ru', path: path)
    ep = rp && Page.find_by(lang: 'en', group_lang_id: rp.group_lang_id)
    if ep
      new_links << [label, ep.path]
    elsif is_bible || is_father
      new_links << [label, is_bible ? 'en-q' : 'en-saints-q']
    end
    # дополнительная вкладка без EN-перевода — пропускаем
  end
  next if new_links.none? { |_, path| path.present? } || p.links == new_links

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
