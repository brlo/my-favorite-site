# Восстанавливает текст 思高聖經, который MybibleImporter.clean стёр вместе с пометой <n>〔…〕</n>.
# В 思高 скобки издания 〔…〕 — текст, отсутствующий в части рукописей; чистка <n>…</n> стирала его
# целиком: в частично обёрнутых стихах терялась оговорка (напр. Ис 11:3), целиком обёрнутые стихи
# (13 шт.) пропадали вовсе. Лечится аналогом fix_brackets.rb (ko-nkrv): скобки издания сохраняем.
#   cn-sbt — прямым текстом из модуля; cn-sb — той же чисткой + t2s (TSCharacters OpenCC,
#   著→着 藉→借) + кавычки «→“ 」→” (внутренние 『』 остаются, как в исходном импорте cn-sb).
# Запуск: bin/rails runner script/translations/bible/fix_brackets_zh.rb [tmp/cn_bible/sigao_trad.sqlite3]
db = ::SQLite3::Database.new(ARGV[0] || 'tmp/cn_bible/sigao_trad.sqlite3', readonly: true)
san = ::Rails::Html::FullSanitizer.new

t2s = {}
::File.readlines(::Rails.root.join('tmp/cn_bible/TSCharacters.txt'), encoding: 'utf-8').each do |line|
  key, _, values = line.strip.partition("\t")
  v = values.split.first
  t2s[key] = v if v
end
t2s['著'] = '着'; t2s['藉'] = '借'
to_sb = ->(text) { text.chars.map { |ch| t2s[ch] || ch }.join.gsub('「', '“').gsub('」', '”') }

zh_bibles = { 'cn-sb' => to_sb, 'cn-sbt' => ->(t) { t } }
created, updated, diverged = 0, 0, []

db.execute("SELECT book_number, chapter, verse, text FROM verses WHERE text LIKE '%<n>〔%' ORDER BY book_number, chapter, verse").each do |book_id, c, v, orig|
  book = ::MybibleImporter::BOOK_BY_ID[book_id.to_i]
  raise "нет книги MyBible #{book_id}" if book.nil?

  trad_text = ::MybibleImporter.clean(orig.gsub(%r{<n>(〔.*?〕)</n>}m, '\1')) # скобки издания сохраняем
  raise "чистка съела весь текст #{book} #{c}:#{v}" if trad_text.blank?

  zh_bibles.each do |tr, convert|
    new_text = convert.(trad_text)
    expected_old = convert.(::MybibleImporter.clean(orig)) # как стих выглядел после исходного импорта
    verse = ::Verse.find_by(tr_code: tr, book: book, chapter: c.to_i, line: v.to_i)
    # baseline: исходный импорт ИЛИ текст уже восстановлен в чужой графике (дефект первого прогона)
    if verse && verse.text != expected_old && verse.text != trad_text
      diverged << "#{tr} #{book} #{c}:#{v}: текст в базе не сходится с модулем, пропущен"
      next
    end
    next if verse&.text == new_text

    verse ||= ::Verse.new(tr_code: tr, lang: tr == 'cn-sb' ? 'zh-Hans' : 'zh-Hant', book_id: book_id.to_i,
                          book: book, zavet: ::BOOKS[book][:zavet] == 2, address: "#{book}:#{c.to_i}:#{v.to_i}",
                          chapter: c.to_i, line: v.to_i, data: { 'orig' => orig })
    verse.text = new_text
    verse.text_search = san.sanitize(new_text).gsub("\u00AD", '')
    verse.save!
    verse.new_record? ? created += 1 : updated += 1
    ::Verse.where(id: verse.id).update_all(
      ::Verse.sanitize_sql(["text_tsvector = to_tsvector(?, text_search)", ::LANG_TO_PG_LANGUAGE[verse.lang] || 'simple']))
  end
end
db.close

puts "создано: #{created}, обновлено: #{updated}"
puts "--- расхождения (#{diverged.size}) ---"
diverged.each { puts _1 }
