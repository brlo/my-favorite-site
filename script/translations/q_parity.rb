# Контроль качества перевода раздела цитат (паритет с русским эталоном)
#
#   bin/rails runner script/translations/q_parity.rb LANG FILE [--spans|--links|--summary]
#
# LANG  — язык перевода (en, ko, zh-Hans, ...), FILE — YAML партии (например db/translations/en/q_saints_1.yml).
# Проверяет для каждой статьи YAML:
#   * счётчики разметки и структуру против русской статьи-эталона (blockquote, strong, mark, em,
#     h2/h3, ul/ol/li, p, в т.ч. абзацы внутри цитат);
#   * последовательность открытия/закрытия strong/mark/em/u в каждой цитате (рисунок выделений);
#   * ссылки: стихи существуют в Библии языка, подписи совпадают с названием книги,
#     страницы библиотеки существуют, нет azbyka и ссылок на русские статьи без lang="ru";
#   * сырую разметку, пустые/несбалансированные теги.
#
# --spans  — дополнительно печатает верхнеуровневые выделения по каждой цитате: RU | перевод
#            (для смысловой сверки границ выделений человеком или ревьюером).
# --links  — только проверка ссылок.
# --summary — только сводка паритета.
#
# Код возврата 1, если есть расхождения (удобно для приёмки партии).
require 'yaml'
require 'cgi'

lang, file, *flags = ARGV
abort 'usage: q_parity.rb LANG FILE [--spans|--links|--summary] [--strict]' unless lang && file
strict = flags.include?('--strict')
mode = (flags - ['--strict']).find { |f| f.start_with?('--') }&.delete_prefix('--')
data = YAML.load_file(file)
short = I18n.t('books.short', locale: lang.to_sym).transform_keys(&:to_s)
TAGS = %w[blockquote strong mark em h2 h3 h4 ul ol li p u hr]

def stat(body)
  TAGS.to_h { |t| [t, body.scan(/<#{t}[ >]/).size] }
end

def qstat(q)
  s = q.scan(/<strong[ >]/).size
  m = q.scan(/<mark[ >]/).size
  e = q.scan(/<em[ >]/).size
  u = q.scan(/<u[ >]/).size
  nest = q.scan(%r{<strong>\s*<mark>}).size
  [s, m, e, u, nest]
end

def tagseq(q) = q.scan(%r{</?(?:strong|mark|em|u)>}).map { _1.delete('<>/') }.join(',')

def headings(body) = body.scan(/<h([234])[ >]/).map { "h#{_1[0]}" }

def pq(body) = body.scan(%r{<blockquote>.*?</blockquote>}m).sum { _1.scan(/<p[ >]/).size }

def text_spans(q)
  out = []
  stack = []
  q.scan(%r{<(/?)(strong|mark|em|u)>|([^<]+)}m) do |close, tag, text|
    if tag
      if close == '/'
        st = stack.pop or next
        st[:inner] = CGI.unescapeHTML(st[:inner].gsub(/<[^>]+>/, '')).gsub(/\s+/, ' ').strip
        if stack.empty?
          out << st
        else
          stack.last[:children] << st
        end
      else
        stack << { tag: tag, inner: '', children: [] }
      end
    elsif text && !stack.empty?
      stack.each { |st| st[:inner] += text }
    end
  end
  out
end

def fmt_span(st)
  s = "#{st[:tag]}{#{st[:inner]}}"
  s += st[:children].map { |c| "(#{c[:tag]}: #{c[:inner]})" }.join if st[:children].any?
  s
end

def balanced?(body)
  allowed = %w[blockquote strong mark em h2 h3 h4 ul ol li p a br i b u sup sub hr figure figcaption img table tr td th]
  stack = []
  bad = []
  body.scan(%r{<(/?)([a-zA-Z0-9]+)[^>]*?(/?)>}) do |close, tag, selfclose|
    next unless allowed.include?(tag)
    next if selfclose == '/' || %w[br img hr].include?(tag)
    if close == '/'
      stack.last == tag ? stack.pop : bad << "закрытие </#{tag}>, ожидалось </#{stack.last}>"
    else
      stack << tag
    end
  end
  bad.empty? && stack.empty? ? nil : (bad.first(3) + ["незакрытые: #{stack.inspect}"])
end

# --- ссылки ---------------------------------------------------------------
def norm_label(s)
  s.to_s.gsub('.', '').gsub(/[\u00a0\u2009\u200a\s]+/, ' ').strip
end

def check_links(body, path, lang, short, page_paths, verse_lines_cache)
  errs = []
  body.scan(%r{<a [^>]*href="([^"]+)"[^>]*>(.*?)</a>}m) do |href, txt|
    label = norm_label(txt.gsub(/<[^>]+>/, ''))
    case href
    when %r{bibleox\.com/[a-z-]+/#{Regexp.escape(lang)}/([a-z0-9-]+)/([a-z0-9]+)/(\d+)/?(?:#L([\d,\-]+))?}
      code, bk, ch, ls = $1, $2, $3, $4
      nums = ls ? ls.split(',').flat_map { |x| a, z = x.split('-').map(&:to_i); (a..(z || a)).to_a } : [1]
      lines = (verse_lines_cache[[code, bk, ch.to_i]] ||= Verse.where(tr_code: code, book: bk, chapter: ch.to_i).pluck(:line).to_set)
      missing = nums.reject { |n| lines.include?(n) }
      errs << "#{path}: #{href} — нет стихов #{missing.inspect}" if missing.any?
      want = bk == 'prsir' ? 'Sir' : norm_label(short[bk])
      errs << "#{path}: подпись «#{label}» не похожа на «#{want} #{ch}:#{ls}»" unless want.empty? || label.include?(want)
    when %r{bibleox\.com/[a-z-]+/#{Regexp.escape(lang)}/w/([^"#]+)}
      ep = CGI.unescape($1)
      errs << "#{path}: нет страницы библиотеки #{ep}" unless page_paths.include?(ep.downcase)
    when %r{bibleox\.com/ru/ru/}
      errs << "#{path}: ссылка на русскую статью без lang=\"ru\": #{href}" unless body[/<a [^>]*href="#{Regexp.escape(href)}"[^>]*lang="ru"/]
    when /azbyka/
      errs << "#{path}: внешняя azbyka-ссылка #{href}"
    end
  end
  errs
end

# --- проверка -------------------------------------------------------------
page_paths = Page.where(lang: lang).pluck(:path_low).to_set
verse_lines_cache = {}
all_errs = []
warns = []
summary = []
data.fetch('pages').each do |p|
  path = p['path']
  body = p['body'].to_s
  ru = Page.find_by(lang: 'ru', path: p['src'])
  unless ru
    all_errs << "#{path}: нет русской статьи #{p['src']}"
    next
  end
  ru_body = ru.body.to_s
  rs = stat(ru_body); ns = stat(body)
  diffs = TAGS.map { |t| "#{t}:#{ns[t]}/#{rs[t]}" if ns[t] != rs[t] }.compact
  hd = headings(ru_body) == headings(body) ? nil : "заголовки RU=#{headings(ru_body)} EN=#{headings(body)}"
  rq = ru_body.scan(%r{<blockquote>.*?</blockquote>}m)
  nq = body.scan(%r{<blockquote>.*?</blockquote>}m)
  qd = []
  qw = []
  [rq.size, nq.size].max.times do |i|
    a = rq[i] && qstat(rq[i]); b = nq[i] && qstat(nq[i])
    qd << "Q#{i + 1} RU=#{a.inspect} #{lang}=#{b.inspect}" if a != b
    if a == b
      rs_seq = tagseq(rq[i].to_s).split(',')
      ns_seq = tagseq(nq[i].to_s).split(',')
      if rs_seq != ns_seq
        j = (0...[rs_seq.size, ns_seq.size].min).find { |x| rs_seq[x] != ns_seq[x] } || [rs_seq.size, ns_seq.size].min
        ctx = ->(arr) { arr[[j - 3, 0].max, 7].to_a.join(',') }
        qw << "Q#{i + 1}: порядок тегов отличается от RU на позиции #{j + 1} (счётчики совпадают; при ином порядке слов допустимо — сверить смысловые границы): RU[#{ctx.(rs_seq)}] #{lang}[#{ctx.(ns_seq)}]"
      end
    end
  end
  qd << "число цитат RU=#{rq.size} #{lang}=#{nq.size}" if rq.size != nq.size
  pd = pq(ru_body) == pq(body) ? nil : "p в цитатах RU=#{pq(ru_body)} #{lang}=#{pq(body)}"
  bal = balanced?(body)
  arrows = body.scan(/(\*\*|::|~~|\[\[|\|\|\|)/).flatten
  raw = arrows.empty? ? nil : "сырая разметка: #{arrows.uniq.inspect}"

  is_ok = diffs.empty? && qd.empty? && !hd && !pd
  summary << format('%-50s %s', path, is_ok ? (qw.empty? ? 'OK' : 'OK (рисунок*)') : 'DIFF')
  all_errs << "#{path}: #{diffs.join(' ')}" if diffs.any?
  all_errs << "#{path}: #{hd}" if hd
  qd.each { |x| all_errs << "#{path}: #{x}" }
  qw.each { |x| warns << (strict ? "#{path}: #{x}" : "#{path}: #{x}") }
  all_errs << "#{path}: #{pd}" if pd
  all_errs << "#{path}: баланс тегов — #{bal.inspect}" if bal
  all_errs << "#{path}: #{raw}" if raw
  all_errs.concat(check_links(body, path, lang, short, page_paths, verse_lines_cache))

  next unless mode == 'spans'
  puts "\n### #{path}"
  [rq.size, nq.size].max.times do |i|
    puts "  Q#{i + 1}"
    puts "  RU: #{(rq[i] ? text_spans(rq[i]).map { fmt_span(_1) } : []).join(' | ')}"
    puts "  #{lang.upcase}: #{(nq[i] ? text_spans(nq[i]).map { fmt_span(_1) } : []).join(' | ')}"
  end
end

puts summary.join("\n")
puts
unless warns.empty?
  puts 'Предупреждения (рисунок тегов при совпадающих счётчиках):'
  puts warns.map { |w| "  #{w}" }.join("\n")
  puts
  all_errs.concat(warns) if strict
end
if mode == 'links'
  link_errs = all_errs.select { |e| e.include?('стих') || e.include?('подпись') || e.include?('библиотек') || e.include?('azbyka') || e.include?('русскую статью') }
  if link_errs.empty?
    puts 'Ссылки: OK'
  else
    puts link_errs.join("\n")
    exit 1
  end
elsif mode == 'summary'
  # только сводка паритета; код возврата всё равно отражает расхождения
  exit 1 if all_errs.any?
else
  if all_errs.empty?
    puts "Паритет с RU и ссылки: OK#{" (есть предупреждения по рисунку тегов — см. выше)" unless warns.empty?}"
  else
    puts all_errs.join("\n")
    exit 1
  end
end
