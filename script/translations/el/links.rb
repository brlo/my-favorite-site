# Вкладки-переключатели («Αγία Γραφή / Ιεροί Πατέρες» и доп.) для el-страниц по RU-эталону.
#   bin/rails runner tmp/el_quotes/el_links.rb [--dry|--check]
# Аналог script/translations/en_links.rb для проекта el (docs/quotes-quality.md, шаг 7).
# Правила те же: путь соседа ищется по group_lang_id; если перевода соседа нет —
# основные вкладки ведут на список раздела (el-q / el-saints-q), но только если он существует;
# дополнительные вкладки без перевода подписи — пропускаются. Идемпотентен.
bible_labels = ['По Библии', 'По Писанию', 'Писание']
father_labels = ['По святым отцам', 'Предание']
LISTS = { bible: 'el-q', father: 'el-saints-q' }.freeze
LABELS = {
  'По Библии' => 'Αγία Γραφή', 'По Писанию' => 'Αγία Γραφή', 'Писание' => 'Γραφή',
  'По святым отцам' => 'Ιεροί Πατέρες', 'Предание' => 'Παράδοση',
  # дополнительные вкладки — переводить по мере партий; без записи в словаре вкладка пропускается
}.freeze

dry = ARGV.include?('--dry')
check = ARGV.include?('--check')
# Не грузим все ru-страницы с телами: на проде их тысячи, это давало минуты
# и заметный CPU. Нужны только группы el-страниц и колонка links.
el_pages = Page.where(lang: 'el').where.not(group_lang_id: nil)
               .select(:id, :path, :path_low, :group_lang_id, :links).to_a
ru_by_group = Page.where(lang: 'ru', group_lang_id: el_pages.map(&:group_lang_id))
                  .select(:id, :group_lang_id, :links).index_by(&:group_lang_id)
changed = 0
report = []

el_pages.each do |p|
  r = ru_by_group[p.group_lang_id] or next
  next if r.links.blank?
  is_list = %w[el-q el-saints-q].include?(p.path_low)
  new_links = []
  r.links.each do |orig, path|
    is_bible = bible_labels.include?(orig)
    is_father = father_labels.include?(orig)
    next if !is_bible && !is_father && !LABELS.key?(orig) # доп. вкладка без перевода — пропускаем
    label = if is_list
              is_bible ? 'Γραφή' : (is_father ? 'Παράδοση' : LABELS[orig])
            else
              LABELS[orig]
            end
    if path.blank?
      new_links << [label, '']
      next
    end
    rp = Page.where(lang: 'ru', path: path).select(:id, :group_lang_id).first
    ep = rp && Page.where(lang: 'el', group_lang_id: rp.group_lang_id).select(:id, :path).first
    if ep
      new_links << [label, ep.path]
    elsif is_bible || is_father
      list = Page.where(lang: 'el', path_low: LISTS[is_bible ? :bible : :father]).select(:id, :path).first
      new_links << [label, list.path] if list # списка ещё нет — вкладку пропускаем
    end
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
