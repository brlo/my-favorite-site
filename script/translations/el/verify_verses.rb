# Проверка черновика el-статьи: текст каждой цитаты == текст модуля gr-lxx-byz.
#   bin/rails runner tmp/el_quotes/verify_verses.rb <draft.html | каталог out/>
# Ссылки цитаты → стихи из БД → склейка (с &lt;…&gt; в разрывах) → сравнение с текстом цитаты
# (без тегов и кавычек-обёртки). Обрезка краёв (<< >>) допустима — отмечается отдельно.
require 'cgi'

def check_file(path)
  draft = File.read(path)
  name = File.basename(path)
  quotes = draft.scan(%r{<blockquote>.*?</blockquote>}m)
  ok = 0
  errs = []
  notes = []
  quotes.each_with_index do |q, i|
    text = q[/«(.*?)»\s*\(/m, 1]
    if text.nil?
      # blockquote с прозой (например, толкование отца), а не библейская цитата
      notes << "Q#{i + 1}: пропущено (blockquote без цитаты «…»)"
      next
    end
    refs = q.scan(%r{bibleox\.com/el/gr-lxx-byz/([a-z0-9-]+)/(\d+)/#L([\d,\-]+)})
    errs << "Q#{i + 1}: нет ссылок на стихи" and next if refs.empty?
    bk, ch, ls = refs[0]
    ch = ch.to_i
    nums = ls.split(',').flat_map { |x| a, z = x.split('-').map(&:to_i); (a..(z || a)).to_a }
    rows = Verse.where(tr_code: 'gr-lxx-byz', book: bk, chapter: ch, line: nums).pluck(:line, :text).to_h
    parts = []; prev = nil
    nums.each do |n|
      t = rows[n].to_s.gsub(%r{<br>|</?[a-z]+>}, '').squeeze(' ').strip
      errs << "Q#{i + 1}: пустой стих #{bk} #{ch}:#{n}" and next if t.size < 3
      parts << (prev && n != prev + 1 ? '&lt;…&gt;' : nil) << t
      prev = n
    end
    mod = parts.compact.join(' ').gsub(/\s+/, ' ').strip
    dt = text.gsub(/<[^>]+>/, '').squeeze(' ').strip
    if CGI.unescapeHTML(dt) == CGI.unescapeHTML(mod)
      ok += 1
    elsif CGI.unescapeHTML(mod).include?(CGI.unescapeHTML(dt))
      ok += 1
      notes << "Q#{i + 1}: обрезка краёв (цитата — подстрока модуля) #{bk} #{ch}:#{ls}"
    else
      a = CGI.unescapeHTML(dt); b = CGI.unescapeHTML(mod)
      j = (0...[a.size, b.size].min).find { |x| a[x] != b[x] }
      errs << "Q#{i + 1}: РАСХОЖДЕНИЕ с модулем #{bk} #{ch}:#{ls} на позиции #{j}\n  DRAFT : …#{a[[j - 40, 0].max, 90]}\n  MODULE: …#{b[[j - 40, 0].max, 90]}\n  МОДУЛЬ ЦЕЛИКОМ: #{b[0, 500]}"
    end
  end
  puts "#{name}: цитат #{quotes.size}, дословно #{ok}"
  notes.each { |n| puts "  note: #{n}" }
  if errs.empty?
    puts '  VERBATIM: OK'
  else
    errs.each { |e| puts "  #{e}" }
    $failed = true
  end
end

target = ARGV[0] or abort 'usage: verify_verses.rb <draft.html | каталог out/>'
files = File.directory?(target) ? Dir.glob(File.join(target, '*.html')).sort : [target]
abort 'нет файлов' if files.empty?
$failed = false
files.each { |f| check_file(f) }
exit 1 if $failed
