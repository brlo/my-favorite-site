# Дозамена божественных 神→上帝, пропущенных при сборке 上帝版 (в CUVt маркер 　神
# стоит не везде; эти стихи имели 神 без маркера). Сверено с опубликованным 上帝版
# (wd.bible pycuv): 1Пар 21:31 耶和华上帝的殿; Деян 3:18; 11:9; 13:33; Ин 13:32 — 上帝.
# Остальные 神 издание сохраняет (языческие боги, 神像, 神人, идиомы, 圣神的灵 у Дан).
# bin/rails runner script/translations/bible/fix_shangti_shen.rb
san = ::Rails::Html::FullSanitizer.new
FIXES = {
  '1par:21:31' => { '耶和华神的殿' => '耶和华上帝的殿', '耶和華神的殿' => '耶和華上帝的殿' },
  'act:3:18'   => { '神曾藉' => '上帝曾藉' },
  'act:11:9'   => { '神所洁净的' => '上帝所洁净的', '神所潔淨的' => '上帝所潔淨的' },
  'act:13:33'  => { '神已经向我们' => '上帝已经向我们', '神已經向我們' => '上帝已經向我們' },
  'in:13:32'   => { '神要因自己荣耀人子' => '上帝要因自己荣耀人子', '神要因自己榮耀人子' => '上帝要因自己榮耀人子' },
}.freeze
changed = 0
%w[cn-cuv cn-cuvt].each do |tr|
  FIXES.each do |address, pairs|
    verse = ::Verse.find_by(tr_code: tr, address: address)
    raise "нет стиха #{tr} #{address}" unless verse
    new_text = verse.text
    pairs.each do |from, to|
      next unless new_text.include?(from)
      new_text = new_text.sub(from, to)
      changed += 1
    end
    next if new_text == verse.text
    verse.update!(text: new_text, text_search: san.sanitize(new_text).gsub("\u00AD", ''))
    ::Verse.where(id: verse.id).update_all(
      ::Verse.sanitize_sql(["text_tsvector = to_tsvector(?, text_search)", ::LANG_TO_PG_LANGUAGE[verse.lang] || 'simple']))
    puts "#{tr} #{address}: #{verse.text[0, 40]}"
  end
end
puts "замена произведена в #{changed} местах"
