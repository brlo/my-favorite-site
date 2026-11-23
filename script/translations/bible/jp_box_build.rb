# Собирает MyBible-модуль перевода jp-box из YAML-глав (db/translations/bible/jp-box/*.yml).
#
#   bin/rails runner script/translations/bible/jp_box_build.rb          # только модуль
#   IMPORT=1 bin/rails runner script/translations/bible/jp_box_build.rb # + импорт в базу
#
# Разметка YAML:
#   漢字[かな]   — фуригана
#   〔…〕        — расхождение с критическим изданием (в тексте стоит чтение Церкви)
#   {A|B}       — калька: A общепринятая, B православная
#   <j>…</j>    — слова Иисуса (красные)
#   ⟨пояснение⟩ — звёздочка после предыдущего слова; текст идёт в data['notes'] стиха
require 'sqlite3'
require 'yaml'
require 'fileutils'

DIR = Rails.root.join('db/translations/bible/jp-box')
OUT = Rails.root.join('tmp/bibles/JP-BOX.SQLite3')
NOTE_RE = /⟨([^⟩]*)⟩/

rows = []
notes_by_address = {}

Dir[DIR.join('*.yml')].sort.each do |file|
  data = YAML.load_file(file)
  book = data.fetch('book')
  chapter = data.fetch('chapter').to_i
  book_id = ::BOOKS.fetch(book).fetch(:id)

  data.fetch('verses').each do |line, raw|
    text = raw.to_s
    verse_notes = []
    # ⟨пояснение⟩ -> {{1}}, {{2}}...; сам текст пояснения уходит в data['notes']
    # в подсказке — чистый текст: фуригану из пояснения убираем
    text = text.gsub(NOTE_RE) do
      verse_notes << Regexp.last_match(1).gsub(/\[[\p{Hiragana}\p{Katakana}ー]+\]/, '')
      "{{#{verse_notes.size}}}"
    end

    address = "#{book}:#{chapter}:#{line.to_i}"
    if verse_notes.any?
      notes_by_address[address] = verse_notes.each_with_index.to_h { |t, i| [(i + 1).to_s, t] }
    end

    rows << [book_id, chapter, line.to_i, text]
  end
end

raise 'нет стихов' if rows.empty?

FileUtils.mkdir_p(OUT.dirname)
FileUtils.rm_f(OUT)
db = SQLite3::Database.new(OUT.to_s)
db.execute('CREATE TABLE verses (book_number INTEGER, chapter INTEGER, verse INTEGER, text TEXT)')
ins = db.prepare('INSERT INTO verses (book_number, chapter, verse, text) VALUES (?,?,?,?)')
db.transaction { rows.each { |row| ins.execute(*row) } }
ins.close
db.close

puts "JP-BOX: #{rows.size} стихов из #{Dir[DIR.join('*.yml')].size} глав -> #{OUT}"

if ENV['IMPORT'] == '1'
  puts ::MybibleImporter.call(OUT.to_s, tr_code: 'jp-box', lang: 'ja', is_replace: true).inspect
  notes_by_address.each do |address, notes|
    verse = ::Verse.find_by(tr_code: 'jp-box', address: address)
    next unless verse
    # update_columns, чтобы не пересобирать text_search: маркеры {{n}} в поиск не нужны
    verse.update_columns(data: verse.data.merge('notes' => notes))
  end
  puts "jp-box: сносок #{notes_by_address.values.sum(&:size)} в #{notes_by_address.size} стихах"
end
