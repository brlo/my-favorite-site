# Пересборка черновика el-статьи: текст цитат и подписи ссылок генерируются из БД,
# выделения (strong/mark/em/u) переносятся с черновика по посимвольному выравниванию.
#   bin/rails runner tmp/el_quotes/rebuild.rb <draft.html>
# Выравнивание: БУКВЫ строгие (опечатки/пропуски — ошибка), пунктуация и пробелы —
# пропускаемые (оксия/тония, U+037E/U+0387, лишние запятые в черновике — не ошибки).
require 'cgi'

SHORT = I18n.t('books.short', locale: :el).transform_keys(&:to_s)
BASE = 'https://bibleox.com/el/gr-lxx-byz'
GAP = "\uE000" # токен разрыва &lt;…&gt;

# базовый символ: NFD + снять комбинируемые знаки; не-буквы (пунктуация, пробелы) → nil
def base_char(ch)
  d = ch.unicode_normalize(:nfd).gsub(/[\p{M}]/, '')
  d =~ /[\p{L}\p{N}]/ ? d : nil
end

def verse_text(bk, ch, nums)
  rows = Verse.where(tr_code: 'gr-lxx-byz', book: bk, chapter: ch, line: nums).pluck(:line, :text).to_h
  parts = []; prev = nil; missing = []
  nums.each do |n|
    t = rows[n].to_s.squeeze(' ').strip
    missing << n if t.size < 3
    parts << (prev && n != prev + 1 ? GAP : nil) << t
    prev = n
  end
  [parts.compact.join(' ').gsub(/\s+/, ' ').strip, missing]
end

# Кириллические двойники греческих букв — невидимая ловушка ручного набора; чиним молча.
CYR2GR = {
  'А' => 'Α', 'В' => 'Β', 'Е' => 'Ε', 'К' => 'Κ', 'М' => 'Μ', 'Н' => 'Η', 'О' => 'Ο',
  'Р' => 'Ρ', 'С' => 'Σ', 'Т' => 'Τ', 'У' => 'Υ', 'Х' => 'Χ',
  'а' => 'α', 'е' => 'ε', 'о' => 'ο', 'р' => 'ρ', 'с' => 'σ', 'т' => 'τ', 'у' => 'υ',
  'х' => 'χ', 'к' => 'κ', 'м' => 'μ', 'и' => 'ι', 'н' => 'η', 'в' => 'β', 'г' => 'γ',
  'л' => 'λ', 'п' => 'π', 'ф' => 'φ',
}.freeze
def fix_homoglyphs(s)
  s.gsub(/[#{CYR2GR.keys.join}]/, CYR2GR)
end

# HTML-фрагмент → последовательность [{char:} | {tag:}]
# Сущности разрыва заменяем на GAP-символ ДО сканирования: иначе жадный [^<]+
# поглощает "&lt;…&gt;" внутри текста.
def tokenize(html)
  out = []
  s = fix_homoglyphs(html).gsub('&lt;…&gt;', GAP).gsub('&lt;...&gt;', GAP)
  s.scan(%r{#{GAP}|<[^>]+>|[^<]+}) do |tok|
    if tok == GAP
      out << { char: GAP }
    elsif tok =~ %r{\A<(\/?)([a-zA-Z]+)>\z}
      out << { tag: "#{$2.downcase}#{$1 == '/' ? '/' : ''}" }
    else
      tok.each_char { |c| out << { char: c } }
    end
  end
  out
end

def align(tokens, mod)
  mod_chars = mod.chars
  events = [] # [позиция_в_модуле, тег]
  errors = []
  notes = []
  di = 0
  mi = 0
  fail_di = nil
  tokens.each do |t|
    if t.key?(:tag)
      events << [mi, t[:tag]]
      next
    end
    c = t[:char]
    if c == GAP
      mi += 1 while mi < mod_chars.size && mod_chars[mi] != GAP && base_char(mod_chars[mi]).nil?
      if mi < mod_chars.size && mod_chars[mi] == GAP
        mi += 1
      else
        errors << "в черновике &lt;…&gt;, в модуле здесь нет разрыва: «#{mod_chars[mi, 20].join}»"
        break
      end
      next
    end
    db = base_char(c)
    if db.nil?
      # пунктуация/пробел черновика: если в модуле здесь тоже не-буква — съедаем парой,
      # иначе пропускаем только символ черновика
      mi += 1 if mi < mod_chars.size && mod_chars[mi] != GAP && base_char(mod_chars[mi]).nil?
      next
    end
    if mi >= mod_chars.size
      errors << "черновик длиннее модуля: лишний текст «#{tokens[di..].select { _1.key?(:char) }.map { _1[:char] }.join[0, 40]}»"
      fail_di = di
      break
    end
    mi += 1 while mi < mod_chars.size && mod_chars[mi] != GAP && base_char(mod_chars[mi]).nil?
    if mi < mod_chars.size && base_char(mod_chars[mi]) == db
      mi += 1
    else
      ctx_m = mod_chars[mi, 25].join
      ctx_d = tokens[di, 25].select { _1.key?(:char) }.map { _1[:char] }.join
      errors << "несовпадение букв (draft #{di} / module #{mi}): draft «#{ctx_d}» vs module «#{ctx_m}»"
      fail_di = di
      break
    end
    di += 1
  end
  if errors.empty?
    rest = mod_chars[mi..].to_a.reject { |c| c == GAP || base_char(c).nil? }.join
    errors << "черновик короче модуля: остаток «#{rest[0, 60]}»" unless rest.empty?
  end
  [events, errors, notes, mi, fail_di]
end

def rebuild_quote(bq)
  text = bq[/«(.*?)»\s*\(/m, 1]
  return [nil, 'не найден текст цитаты «…»'] if text.nil?
  refs = bq.scan(%r{bibleox\.com/el/gr-lxx-byz/([a-z0-9-]+)/(\d+)/#L([\d,\-]+)})
  return [nil, 'нет ссылок на стихи'] if refs.empty?

  bk, ch, ls = refs[0]
  nums = ls.split(',').flat_map { |x| a, z = x.split('-').map(&:to_i); (a..(z || a)).to_a }
  mod, missing = verse_text(bk, ch.to_i, nums)
  return [nil, "пустые стихи #{bk} #{ch}:#{missing.inspect}"] if missing.any?

  tokens = tokenize(text)
  notes = []
  emit_from = 0
  events, errors, _notes, _mi, fail_di = align(tokens, mod)
  if errors.any? && fail_di && fail_di <= 2
    # цитата начинается с середины стиха (обрезка <<): ищем смещение в модуле.
    # ВАЖНО: эмиссия текста тоже идёт от смещения — иначе в цитату попадает полный стих.
    best = nil # [end_mi, off, errs]
    1.upto(160) do |off|
      # старт срезаем до первой буквы: пунктуация перед ней относится к обрезанной части
      start = off
      start += 1 while start < mod.size && mod[start] != GAP && base_char(mod[start]).nil?
      ev, errs, _n, m, _f = align(tokens, mod.chars[start..].join)
      if errs.empty?
        events = ev
        emit_from = start
        errors = []
        notes << "обрезано начало модуля (~#{emit_from} симв.: цитата с середины стиха)"
        break
      end
      best = [m, off, errs] if best.nil? || m > best[0]
    end
    if errors.any? && best
      errors << "после отсечения старта (смещение #{best[1]}, прошло #{best[0]} симв.): #{best[2].first}"
    end
  end
  return [nil, errors.join('; ')] if errors.any?

  mod_chars = mod.chars[emit_from..]
  out = []
  mod_chars.each_with_index do |c, i|
    # теги с событием в позиции i вставляются ПЕРЕД символом i
    events.select { |(pos, _)| pos == i }.each { |(_, tag)| out << (tag.end_with?('/') ? "</#{tag.delete('/')}>" : "<#{tag}>") }
    out << (c == GAP ? '&lt;…&gt;' : c)
  end
  events.select { |(pos, _)| pos == mod_chars.size }.each { |(_, tag)| out << (tag.end_with?('/') ? "</#{tag.delete('/')}>" : "<#{tag}>") }

  sig = refs.map do |b, c, l|
    %(<a href="#{BASE}/#{b}/#{c}/#L#{l}">#{SHORT[b]} #{c}:#{l}</a>)
  end.join(' · ')
  # структура цитаты как в RU: blockquote с <p> или без него
  if bq =~ %r{<blockquote>\s*<p[ >]}
    ["<blockquote><p>«#{out.join}» (#{sig})</p></blockquote>", nil, notes]
  else
    ["<blockquote>«#{out.join}» (#{sig})</blockquote>", nil, notes]
  end
end

path = ARGV[0] or abort 'usage: rebuild.rb <draft.html>'
body = File.read(path)
quotes = body.scan(%r{<blockquote>.*?</blockquote>}m)
failed = false
rebuilt = 0
quotes.each do |bq|
  # blockquote с прозой (толкование отца) — не библейская цитата, пропускаем
  next unless bq =~ /«.*?»\s*\(/m
  new_bq, err, qnotes = rebuild_quote(bq)
  if err
    failed = true
    puts "ОШИБКА: #{err}\n  цитата: #{bq[0, 120]}…"
  else
    qnotes.each { |n| puts "note: #{n}" }
    body = body.sub(bq) { new_bq }
    rebuilt += 1
  end
end
# подписи всех ссылок на gr-lxx-byz (в т.ч. в прозе) — канонические (лечит гомоглифы кириллицы)
body = body.gsub(%r{<a href="#{BASE}/([a-z0-9-]+)/(\d+)/#L([\d,\-]+)">[^<]*</a>}) do
  %(<a href="#{BASE}/#{$1}/#{$2}/#L#{$3}">#{SHORT[$1]} #{$2}:#{$3}</a>)
end
# кириллические гомоглифы во всём файле, кроме значений href (там пути с кириллицей легальны)
body = body.gsub(%r{href="[^"]*"|[^"]+}) { |m| m.start_with?('href="') ? m : fix_homoglyphs(m) }
File.write(path, body) unless failed
puts failed ? 'пересборка НЕ выполнена — исправьте ошибки' : "пересобрано цитат: #{rebuilt}"
exit 1 if failed
