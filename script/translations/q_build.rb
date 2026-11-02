# Сборка YAML раздела цитат из компактной разметки: bin/rails runner script/translations/q_build.rb LANG db/translations/LANG/src/NAME.txt
# Результат: db/translations/LANG/q_NAME.yml. Цитаты подставляются из Библии языка дословно, выделения проверяются.
#
# @@ src | path | title | sub | meta | menu parent | menu title | priority     — новая статья (menu можно не указывать)
# # H2 / ## H3 / ### H4 ; "- x" и "1. x" — списки; остальное — абзац
# В тексте: [[mf 16:19]] — ссылка на стих; [[ru:путь|текст]] — ссылка на русскую статью; **жирный**
# > mf 16:19; mk 1:8 :: фраза :: !фраза (жирный+mark) :: <<начало :: >>конец ~~ примечание
#     стих(и) первой ссылки; остальные ссылки только подписываются. Несмежные стихи разделяются <…>.
#     Ссылка с префиксом lang=gr показывается как греческая.
# | свой текст **жирный** ||| gr prs 2:24 ~~ примечание   — цитата своими словами (книги нет в Библии языка: с греческого)
# | текст ||| ctb mf 5:5  — свой текст со ссылкой на Библию языка
# | текст ||| ru 3ezd 3:24  — свой перевод с Синодального (текст есть только в нём)
require 'yaml'
lang, file = ARGV
tr = BibleLinker::BIBLE_BY_LANG.fetch(lang)
short = I18n.t('books.short', locale: lang.to_sym)
NOTE_GR = { 'ko' => '그리스어에서 번역' }.fetch(lang, '')
SOURCE = { 'ko' => '<p>번역: 로디온 블라소프 (AI 도구 활용). 저본: 러시아어 원문. 참고: 영어·일본어 번역. 성경 인용과 링크는 개역개정에 따름.</p>' }.fetch(lang)
errors = []
clean = ->(t) { t.to_s.gsub(/\[[^\]]*\]/, '').gsub(%r{<br>|</?[a-z]+>}, '').squeeze(' ').strip }
quote = ->(t) { i = 0; t.gsub('"') { (i += 1).odd? ? '‘' : '’' } }
expand = ->(ls) { ls.split(',').flat_map { |x| a, z = x.split('-').map(&:to_i); (a..(z || a)).to_a } }
base = "https://bibleox.com/#{lang}"
link = lambda do |r, code: tr|
  bk, rest = r.strip.split(/\s+/); ch, ls = rest.split(':')
  lab = short[bk.to_sym] or errors << "нет книги #{bk}"
  href = ls ? "#{base}/#{code}/#{bk}/#{ch}/#L#{ls}" : "#{base}/#{code}/#{bk}/#{ch}/"
  href = "#{base}/#{code}/#{bk}/#{ch}/#L#{ls}" if ls
  %(<a href="#{href}">#{lab} #{rest}</a>)
end
inline = lambda do |s|
  s.gsub(/\[\[en:([^|\]#]+)(?:#[^|\]]*)?\|([^\]]+)\]\]/) do
    path, txt = $1, $2
    en = Page.find_by(lang: 'en', path_low: path.downcase)
    ru = en && Page.find_by(lang: 'ru', group_lang_id: en.group_lang_id)
    errors << "нет ru для en:#{path}" unless ru
    %(<a href="https://bibleox.com/ru/ru/w/#{ru&.path}">#{txt}</a>)
  end
   .gsub(/\[\[ru:([^|\]]+)\|([^\]]+)\]\]/) { %(<a href="https://bibleox.com/ru/ru/w/#{$1}">#{$2}</a>) }
   .gsub(/\[\[gr ([^\]]+)\]\]/) { link.($1, code: 'gr-lxx-byz') }
   .gsub(/\[\[([^\]|]+)\]\]/) { link.($1) }
   .gsub(/\*\*(.+?)\*\*/) { "<strong>#{$1}</strong>" }
end
verses = lambda do |r|
  bk, rest = r.strip.split(/\s+/); ch, ls = rest.split(':')
  nums = expand.(ls)
  rows = Verse.where(tr_code: tr, book: bk, chapter: ch.to_i, line: nums).pluck(:line, :text).to_h
  parts = []; prev = nil
  nums.each do |n|
    t = clean.(rows[n])
    if t.size < 3 then errors << "пустой стих #{r} [#{n}]"; next end
    parts << (prev && n != prev + 1 ? '&lt;…&gt;' : nil) << t
    prev = n
  end
  quote.(parts.compact.join(' '))
end
locate = lambda do |text, ph, from|
  re = Regexp.new(ph.gsub(/\s+/, '').chars.map { Regexp.escape(_1) }.join('[\s‘’]*'))
  (m = re.match(text, from)) || (m = re.match(text))
  m
end
expand_quote = lambda do |line, title|
  head, note = line.split(/\s*~~\s*/, 2)
  rp, *phs = head.split(/\s*::\s*/)
  rs = rp.split(';').map(&:strip)
  text = verses.(rs[0])
  phs.map(&:strip).select { _1.start_with?('>>') }.each do |p|
    m = locate.(text, p[2..], 0) or next errors << "#{title}: нет конца «#{p}» в #{rs[0]}"
    text = text[0...m.end(0)]
  end
  phs.map(&:strip).select { _1.start_with?('<<') }.each do |p|
    m = locate.(text, p[2..], 0) or next errors << "#{title}: нет начала «#{p}» в #{rs[0]}"
    text = text[m.begin(0)..]
  end
  spans = []
  pos = 0
  phs.map(&:strip).reject { _1.empty? || _1.start_with?('>>', '<<') }.each do |p|
    is_mark = p.start_with?('!')
    m = locate.(text, p.delete_prefix('!'), pos)
    next errors << "#{title}: нет фразы «#{p}» в #{rs[0]}" unless m
    spans << [m.begin(0), m.end(0), is_mark]
    pos = m.end(0)
  end
  spans.sort.reverse.each_cons(2) { |a, b| errors << "#{title}: пересечение выделений в #{rs[0]}" if b[1] > a[0] }
  spans.sort.reverse.each do |a, b, mk|
    inner = text[a...b]
    text[a...b] = mk ? "<strong><mark>#{inner}</mark></strong>" : "<strong>#{inner}</strong>"
  end
  links = rs.map { |r| r.start_with?('gr ') ? link.(r.delete_prefix('gr '), code: 'gr-lxx-byz') : link.(r) }.join('; ')
  %(<blockquote><p>“#{text}” (#{links})#{" <em>(#{inline.(note)})</em>" if note}</p></blockquote>)
end
literal = lambda do |line|
  body, tail = line.split(/\s*\|\|\|\s*/, 2)
  r, note = tail.split(/\s*~~\s*/, 2)
  a = if r.start_with?('grt ') then link.(r.delete_prefix('grt '), code: 'gr-lxx-byz')
      elsif r.start_with?('en ') then "#{link.(r.delete_prefix('en '), code: 'en-nrsv')}, 영어 번역(NRSV)에서 옮김"
      elsif r.start_with?('ru ') then "#{link.(r.delete_prefix('ru '), code: 'ru')}, 러시아어 시노달 역본에서 옮김"
      elsif r.start_with?('gr ') then "#{link.(r.delete_prefix('gr '), code: 'gr-lxx-byz')}, #{NOTE_GR}"
      else r.split(';').map { link.(_1.delete_prefix('ctb ').strip) }.join('; ') end
  %(<blockquote><p>“#{inline.(body)}” (#{a})#{" <em>(#{inline.(note)})</em>" if note}</p></blockquote>)
end
pages = []; cur = nil; list = nil
flush = -> { if list; cur['body'] << "<#{list[0]}>#{list[1].map { "<li><p>#{_1}</p></li>" }.join}</#{list[0]}>"; list = nil; end }
File.readlines(file, chomp: true).each do |l|
  l = l.strip
  next if l.empty? || l.start_with?('//')
  if l.start_with?('@@ ')
    flush.()
    src, path, title, sub, meta, mp, mt, pr = l[3..].split('|').map(&:strip)
    cur = { 'src' => src, 'path' => path, 'title' => title, 'copy_cover' => true, 'body' => +'' }
    cur['title_sub'] = sub if sub.to_s != ''
    cur['meta_desc'] = meta if meta.to_s != ''
    cur['menu'] = { 'parent' => mp, 'title' => mt.to_s == '' ? title : mt, 'priority' => pr.to_i } if mp.to_s != ''
    cur['references'] = SOURCE
    pages << cur
  elsif l.start_with?('^ ')
    cur['references'] = "<ol><li><p>#{inline.(l[2..])}</p></li></ol>" + cur['references']
  elsif l.start_with?('- ') || l =~ /\A\d+\. /
    t = l =~ /\A\d/ ? 'ol' : 'ul'
    flush.() if list && list[0] != t
    list ||= [t, []]
    list[1] << inline.(l.sub(/\A(-|\d+\.) /, ''))
  else
    flush.()
    cur['body'] <<
      case l
      when /\A### / then "<h4>#{inline.(l[4..])}</h4>"
      when /\A## / then "<h3>#{inline.(l[3..])}</h3>"
      when /\A# / then "<h2>#{inline.(l[2..])}</h2>"
      when /\A> / then expand_quote.(l[2..], cur['path'])
      when /\A\| / then literal.(l[2..])
      when /\A<(blockquote|figure|div|table|img)/ then inline.(l)
      else "<p>#{inline.(l)}</p>"
      end
  end
end
flush.()
if errors.any?
  puts errors.uniq, "ОШИБОК: #{errors.uniq.size}"
  exit 1
end
out = "db/translations/#{lang}/q_#{File.basename(file, '.txt')}.yml"
File.write(out, { 'lang' => lang, 'list' => Page.find_by!(lang: lang, parent_id: Page.find_by!(lang: lang, path_low: "links_#{lang}").id, group_lang_id: 'биб-цитаты').path, 'pages' => pages }.to_yaml(line_width: -1))
puts "ok #{out}: #{pages.size} статей"
