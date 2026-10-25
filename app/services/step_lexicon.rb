# Разбор лексиконов STEPBible (Tyndale House, CC BY 4.0, https://github.com/STEPBible/STEPBible-Data):
#   TBESG - Abbott-Smith (словарь НЗ), TFLSJ - полный LSJ, вычитанный под Библию.
# Файлы - TSV с шапкой-описанием; строка статьи начинается с номера Стронга:
#   eStrong  dStrong  uStrong  Greek  Transliteration  Morph  Gloss  Meaning(html)
#
#   StepLexicon.each_row('TBESG ... .txt') { |row| row[:greek] }   # -> {strong:, greek:, forms:, translit:, gloss:, html:}
#   StepLexicon.convert_html(row[:html])                           # -> html для DictWord#desc
class StepLexicon
  # Сокращения книг STEPBible -> код книги сайта (::BOOKS). 1Ki у STEP - это 3-я Царств, 3Ki - LXX-название той же книги.
  BOOKS = {
    'Gen' => 'gen', 'Exo' => 'ish', 'Lev' => 'lev', 'Num' => 'chis', 'Deu' => 'vtor', 'Jos' => 'nav',
    'Jdg' => 'sud', 'Rut' => 'ruf', '1Sa' => '1ts', '2Sa' => '2ts', '1Ki' => '3ts', '2Ki' => '4ts',
    '3Ki' => '3ts', '4Ki' => '4ts', '1Ch' => '1par', '2Ch' => '2par', 'Ezr' => 'ezd', 'Neh' => 'neem',
    '1Es' => '2ezd', 'Est' => 'esf', 'Tob' => 'tov', 'Jdt' => 'iudf', 'Job' => 'iov', 'Psa' => 'ps',
    'Pss' => 'ps', 'PSS' => 'ps', 'Pro' => 'pr', 'Ecc' => 'ekl', 'Sng' => 'pp', 'Wis' => 'prs',
    'Sir' => 'prsir', 'Isa' => 'is', 'Jer' => 'ier', 'Lam' => 'pier', 'Bar' => 'var', 'Ezk' => 'iez',
    'Dan' => 'dan', 'Hos' => 'os', 'Jol' => 'iol', 'Amo' => 'am', 'Oba' => 'av', 'Jon' => 'ion',
    'Mic' => 'mih', 'Nam' => 'naum', 'Hab' => 'avm', 'Zep' => 'sof', 'Hag' => 'ag', 'Zec' => 'zah',
    'Mal' => 'mal', '1Ma' => '1mak', '1Mac' => '1mak', '2Ma' => '2mak', '2Mac' => '2mak',
    '3Ma' => '3mak', '3Mac' => '3mak',
    'Mat' => 'mf', 'Matt' => 'mf', 'Mrk' => 'mk', 'Mark' => 'mk', 'Luk' => 'lk', 'Luke' => 'lk',
    'Jhn' => 'in', 'John' => 'in', 'Act' => 'act', 'Acts' => 'act', 'Rom' => 'rim', '1Co' => '1kor',
    '1Cor' => '1kor', '2Co' => '2kor', 'Gal' => 'gal', 'Eph' => 'ef', 'Php' => 'fil', 'Phil' => 'fil',
    'Col' => 'kol', '1Th' => '1sol', '2Th' => '2sol', '1Ti' => '1tim', '1Tim' => '1tim', '2Ti' => '2tim',
    'Tit' => 'tit', 'Phm' => 'fm', 'Heb' => 'evr', 'Jas' => 'iak', '1Pe' => '1pet', '1Pet' => '1pet',
    '2Pe' => '2pet', '1Jn' => '1in', '1Jo' => '1in', '2Jn' => '2in', '3Jn' => '3in', 'Jude' => 'iud',
    'Rev' => 'otkr',
  }.freeze

  VERSES = '\d+(?:-\d+)?(?:\s*,\s*\d+(?:-\d+)?)*'

  # Строки статей файла: пропускаем шапку и пустые строки
  def self.each_row(path)
    return enum_for(:each_row, path) unless block_given?

    ::File.foreach(path, encoding: 'bom|utf-8') do |line|
      row = parse_line(line)
      yield row if row
    end
  end

  def self.parse_line(line)
    cols = line.chomp.split("\t")
    return unless cols.size >= 8 && cols[0].match?(/\AG\d+\z/)

    greek = cols[3].to_s.unicode_normalize(:nfc).strip
    {
      strong:   cols[0],
      greek:    greek,
      # "α, Ἀλφα" - несколько форм заголовка
      forms:    greek.split(/\s*,\s*/).reject(&:empty?),
      translit: cols[4].to_s.strip.presence,
      gloss:    cols[6].to_s.strip.presence,
      html:     cols[7].to_s,
    }
  end

  # Разметка STEP -> HTML, который пропускает DictWord::ALLOW_TAGS
  def self.convert_html(html)
    s = html.to_s.unicode_normalize(:nfc)
    s = s.gsub(%r{<ref='([^']*)'>(.*?)</ref>}m) { ref_links(::Regexp.last_match(1), ::Regexp.last_match(2)) }
    # всплывающие ссылки на источники: [<a href="javascript:void(0)" title="Hdt. 1.24">Refs 5th c.BC+</a>]
    s = s.gsub(%r{<a\s+href="javascript:void\(0\)"\s+title="([^"]*)"\s*>(.*?)</a>}m) do
      title, label = ::Regexp.last_match.captures
      "<abbr title=\"#{title.gsub(/\s+/, ' ').strip}\">#{label}</abbr>"
    end
    s = s.gsub(%r{</?Level\d>}i, '')                  # <Level2><b>__II</b></Level2> -> <b>II</b>
    s = s.gsub(/__\s*/, '')                            # __1. / __(a) / __α / __III.2.b -> номер пункта
    s = s.gsub(%r{<(?:br|lb)\s*/?>}i, '<br>')
    s = s.gsub(/\{([^{}]*)\}/, '\1')                   # {ἄγνυμι} - отсылка к другой статье
    s = s.gsub(/[ \t]+/, ' ').strip
    s.sub(/\A(?:<br>\s*)+/, '')
  end

  # <ref='Heb.5.4; 7.11'>Heb.5:4, 7:11</ref> -> ссылки на главы Библии сайта (без языка: /evr/5#L4)
  def self.ref_links(ref, text)
    book_abbr, rest = ref.to_s.strip.sub(/[.;,]+\z/, '').split('.', 2)
    code = BOOKS[book_abbr]
    return text if code.nil? || rest.nil?

    single_chapter = ::BOOKS[code][:chapters] == 1
    segments = rest.split(';').map do |seg|
      if (m = seg.strip.match(/\A(\d+)\.(#{VERSES})\z/))
        [m[1].to_i, m[2]]
      elsif single_chapter && (m = seg.strip.match(/\A(#{VERSES})\z/))
        [1, m[1]]
      end
    end

    # разобрать не получилось ("Rev.1.20-2:1") - ведём всю ссылку на первую главу и стих, если они есть
    if segments.any?(&:nil?) || segments.any? { |ch, _| ch > ::BOOKS[code][:chapters] }
      m = rest.match(/\A\s*(\d+)\.(\d+)/)
      return text unless m && m[1].to_i <= ::BOOKS[code][:chapters]

      return chapter_link(code, m[1].to_i, m[2], text)
    end

    segments.each_with_index.map do |(ch, verses), i|
      label = "#{ch}:#{verses.gsub(/\s*,\s*/, ', ')}"
      label = "#{book_abbr}.#{label}" if i.zero?
      chapter_link(code, ch, verses, label)
    end.join('; ')
  end

  def self.chapter_link(code, chapter, verses, text)
    anchor = verses.to_s.gsub(/\s+/, '').presence
    "<a href=\"/#{code}/#{chapter}#{anchor ? "#L#{anchor}" : ''}\">#{text}</a>"
  end
end
