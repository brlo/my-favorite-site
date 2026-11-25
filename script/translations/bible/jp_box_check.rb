# Проверка перевода jp-box: адреса стихов, разметка, сноски, поиск.
#
#   BOOK=mf bin/rails runner script/translations/bible/jp_box_check.rb
#   (без BOOK — Евангелие от Марка)
book = ENV['BOOK'].presence || 'mk'
# Ветхий Завет переводится с LXX и держит её нумерацию (у jp-ni и ru она местами другая:
# Быт 32, Исх 7–8, 21–22, 37–39, Пс 9/113/115), поэтому набор стихов сверяем с gr-lxx-byz.
# В gr-lxx-byz дефект модуля: нет Пс 9:21–38 и 113:19–26 — они переведены по церковному
# тексту и добавляются к набору.
base_tr = ::BOOKS[book][:zavet] == 1 ? 'gr-lxx-byz' : 'jp-ni'
ps_gaps = { 9 => (21..38).to_a, 113 => (19..26).to_a }
# gr-lxx-byz дублирует закон 5:20–26 в 6:1–6 (дефект модуля). По решению пользователя
# держимся csl-ru: закон стоит один раз, в главе 6, поэтому 5:20–26 в переводе опущены.
ot_gaps = { 'lev' => { 5 => (20..26).to_a } }

problems = []
total = 0
red_verses = 0
all_text = +''
chapters = ::Verse.where(tr_code: 'jp-box', book: book).distinct.order(:chapter).pluck(:chapter)

chapters.each do |ch|
  # Греческий модуль хранит Ездру и Неемию одной книгой `ezd` (23 главы):
  # 1–10 — Ездра, 11–23 — Неемия. На сайте это две книги, поэтому сверяем
  # `neem N` с `ezd (N+10)`, а `ezd` — только с главами 1–10.
  gr_book = book
  gr_ch = ch
  if base_tr == 'gr-lxx-byz'
    if book == 'neem'
      gr_book = 'ezd'
      gr_ch = ch + 10
    end
  end
  base = ::Verse.where(tr_code: base_tr, book: gr_book, chapter: gr_ch).pluck(:line).sort
  if book == 'ps'
    base = (base + ps_gaps.fetch(ch, [])).uniq.sort
    # в gr-lxx-byz у Пс 115 текст сдвинут на 9 строк (1–9 стоят как «.»), сверяем с ru
    base = ::Verse.where(tr_code: 'ru', book: 'ps', chapter: 115).pluck(:line).sort if ch == 115
  end
  base -= ot_gaps.dig(book, ch).to_a
  rows = ::Verse.where(tr_code: 'jp-box', book: book, chapter: ch).order(:line).to_a
  total += rows.size
  got = rows.map(&:line).sort
  problems << "#{book}#{ch}: нет стихов #{(base - got).inspect}" if (base - got).any?
  extra = got - base
  extra -= [0] if book == 'ps' # надписание может отсутствовать в греческом модуле
  problems << "#{book}#{ch}: лишние стихи #{extra.inspect}" if extra.any?

  rows.each do |v|
    t = v.text.to_s
    all_text << t
    problems << "#{v.address}: пусто" if t.strip.empty?
    problems << "#{v.address}: непарные [" if t.count('[') != t.count(']')
    problems << "#{v.address}: остался ⟨" if t.include?('⟨')
    problems << "#{v.address}: кириллица" if t =~ /[\u0400-\u04ff]/
    t.scan(/\[([^\]]*)\]/) { |m| problems << "#{v.address}: фуригана #{m[0]}" unless m[0] =~ /\A[ぁ-んァ-ヶー]+\z/ }
    red_verses += 1 if t.include?('<j>')
    t.scan(/\{\{(\d+)\}\}/) do |m|
      problems << "#{v.address}: нет сноски #{m[0]}" unless v.data.to_h['notes'].to_h.key?(m[0])
    end
    (v.data.to_h['notes'] || {}).each_key do |k|
      problems << "#{v.address}: сноска #{k} не используется" unless t.include?("{{#{k}}}")
    end
    problems << "#{v.address}: маркер в text_search" if v.text_search.to_s.include?('{{')
  end
end

[['〔', '〕'], ['<j>', '</j>'], ['<mo>', '</mo>']].each do |a, b|
  ca = all_text.scan(a).size
  cb = all_text.scan(b).size
  problems << "непарные #{a} по книге: #{ca}/#{cb}" if ca != cb
end

done = chapters.size
all_ch = ::BOOKS[book][:chapters]
puts "#{book}: глав #{done} из #{all_ch}, стихов #{total}, с красным #{red_verses}, " \
     "〔〕 #{all_text.scan('〔').size}, сносок #{::Verse.where(tr_code: 'jp-box', book: book).to_a.sum { |v| v.data.to_h['notes'].to_h.size }}"
puts "готовы главы: #{chapters.join(', ')}" if done < all_ch
puts problems.any? ? "ПРОБЛЕМЫ (#{problems.size}):\n#{problems.first(30).join("\n")}" : 'проблем нет'
