# Компактный вид статей для перевода раздела цитат: структура английской статьи + стихи целевой Библии.
#   bin/rails runner script/translations/view_q.rb LANG file:q_god_1 | src1 src2 | list:god   (list — все статьи без YAML: из базы)
# В цитатах английский текст не печатается: только ссылки, выделения (B жирный, M жирный+mark), заметки.
require 'yaml'
lang, *args = ARGV
tr = BibleLinker::BIBLE_BY_LANG.fetch(lang)
Quote = ->(t) { i = 0; t.gsub('"') { (i += 1).odd? ? '‘' : '’' } }
clean = ->(t) { t.to_s.gsub(/\[[^\]]*\]/, '').gsub(%r{<br>|</?[a-z]+>}, '').squeeze(' ').strip.gsub('하나님', '하느님') }
expand = ->(ls) { ls.split(',').flat_map { |x| a, z = x.split('-').map(&:to_i); (a..(z || a)).to_a } }
yaml_items = {}
Dir['db/translations/en/*.yml'].sort.each { |f| (YAML.load_file(f)['pages'] || []).each { |p| yaml_items[p['src']] = p.merge('file' => File.basename(f, '.yml')) } }
ru_list = Page.find_by!(lang: 'ru', path_low: 'q')
skip = %w[test храм_и_жертвы библия-ветхий-и-новый-завет]
all_db = Page.where(lang: 'ru', parent_id: ru_list.id).pluck(:path).reject { yaml_items.key?(_1) || skip.include?(_1) }
item_for = lambda do |src|
  yaml_items[src] || begin
    ru = Page.find_by!(lang: 'ru', path: src)
    en = Page.find_by!(lang: 'en', group_lang_id: ru.group_lang_id)
    m = Menu.where(page_id: Page.find_by!(lang: 'en', path_low: 'en-q').id, path: en.path).first
    chain = []; x = m&.parent_id
    while x; pm = Menu.find(x); chain.unshift(pm.title); x = pm.parent_id; end
    { 'src' => src, 'path' => en.path, 'title' => en.title, 'title_sub' => en.title_sub, 'meta_desc' => en.meta_desc, 'body' => en.body, 'references' => en.references,
      'menu' => m && { 'parent' => chain.join('/'), 'title' => m.title, 'priority' => m.priority }, 'file' => 'db' }
  end
end
ref = ->(a) { h = a['href'].to_s; (m = h.match(%r{bibleox\.com/[a-z]+/([a-z0-9-]+)/([0-9a-z]+)/(\d+)/?(?:#L([\d,\-]+))?$})) && m[1] != 'ru' && m[1] != 'en' && !h.include?('/w/') ? "#{m[2]} #{m[3]}:#{m[4]}" : nil }
inline = lambda do |n|
  n.children.map do |c|
    if c.text? then c.text
    elsif c.name == 'a' then (r = ref.(c)) ? "[[#{r}]]" : "[[LINK #{CGI.unescape(c['href'].to_s)}|#{c.text}]]"
    elsif c.name == 'strong' then "**#{c.text}**"
    else inline.(c) end
  end.join
end
srcs = args.flat_map do |a|
  if a.start_with?('file:') then yaml_items.values.select { _1['file'] == a.delete_prefix('file:') }.map { _1['src'] }
  elsif a == 'db' then all_db
  else [a] end
end
done = Page.where(lang: lang).where.not(body: [nil, '']).pluck(:group_lang_id).to_set
srcs.each do |src|
  ru = Page.find_by(lang: 'ru', path: src)
  next puts("SKIP #{src}") if ru && done.include?(ru.group_lang_id)

  it = item_for.(src)
  puts "@@ #{src} | #{it['path']} | #{it['title']} | sub=#{it['title_sub']} | meta=#{it['meta_desc']} | menu=#{it['menu']}"
  puts "REFS: #{it['references']}" if it['references'].present?
  doc = Nokogiri::HTML.fragment(it['body'].to_s)
  refs = []
  doc.children.each do |n|
    case n.name
    when /h(\d)/ then puts "#{'#' * ($1.to_i - 1)} #{n.text.strip}"
    when 'p' then n.css('img').each { puts "IMG #{_1.to_html}" }; puts "P #{inline.(n)}"; n.css('a').each { r = ref.(_1); refs << r if r }
    when 'ul', 'ol' then n.css('li').each { |li| puts "#{n.name == 'ol' ? '1.' : '-'} #{inline.(li).strip}"; li.css('a').each { r = ref.(_1); refs << r if r } }
    when 'blockquote'
      as = n.css('a').map { ref.(_1) }.compact; refs.concat(as)
      b = n.css('strong').map { |s| (s.at_css('mark') || s.parent.name == 'mark' ? 'M:' : '') + s.text.strip }.reject(&:empty?)
      tail = n.css('p').map(&:text).select { _1 !~ /\A\s*[“"«]/ && _1 !~ /\(\s*\z/ }.join(' / ').strip
      full = as.empty? ? " TEXT: #{n.text.strip}" : ''
      puts "> #{as.uniq.join('; ')} :: #{b.join(' :: ')}#{" ~~ #{tail}" if tail.size.between?(1, 400)}#{full}"
    else puts "? #{n.to_html[0, 200]}" unless n.text.strip.empty?
    end
  end
  seen = {}
  puts '---'
  refs.each do |r|
    next if seen[r]; seen[r] = true
    bk, rest = r.split(' '); ch, ls = rest.split(':')
    next if ls.nil? || ls.empty? || expand.(ls).size > 45
    vs = Verse.where(tr_code: tr, book: bk, chapter: ch.to_i, line: expand.(ls)).order(:line).map { "[#{_1.line}]#{Quote.(clean.(_1.text))}" }.join(' ')
    if vs.strip.empty?
      g = Verse.where(tr_code: 'gr-lxx-byz', book: bk, chapter: ch.to_i, line: expand.(ls)).order(:line).map { "[#{_1.line}]#{clean.(_1.text)}" }.join(' ')
      puts "#{r} NOVERSE GR: #{g}"
    else
      puts "#{r}: #{vs}"
    end
  end
  puts
end
