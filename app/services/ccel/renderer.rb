# Раздел тома CCEL (ThML) -> HTML страницы сайта:
#   body       - текст; подразделы стали заголовками h2-h4, сноски - маркерами [N]
#   notes      - тексты сносок по порядку (HTML внутри одного абзаца)
#   pages      - номера печатных страниц раздела [первая, последняя]
#
# Разделы составителей сборника (вступления, пояснения, экскурсы) пропускаем: нужны только тексты самих авторов.
#
# Ссылки на Писание (<scripRef parsed="|Phil|4|3|0|0">) переписываются в вид "Phil. 4:3",
# который распознают BibleLinker и BibleCitationExtractor. Сноска, в которой нет ничего,
# кроме ссылок на Писание, не становится сноской: ссылка встаёт прямо в текст в скобках.
module Ccel
  class Renderer
    Result = Struct.new(:body, :notes, :pages, keyword_init: true)

    # OSIS-код книги -> сокращение, которое понимает BOOK_TO_CODE
    BOOK_ABBR = {
      'Gen' => 'Gen.', 'Exod' => 'Exod.', 'Lev' => 'Lev.', 'Num' => 'Num.', 'Deut' => 'Deut.',
      'Josh' => 'Josh.', 'Judg' => 'Judg.', 'Ruth' => 'Ruth', '1Sam' => '1 Sam.', '2Sam' => '2 Sam.',
      '1Kgs' => '1 Kgs.', '2Kgs' => '2 Kgs.', '1Chr' => '1 Chr.', '2Chr' => '2 Chr.', 'Ezra' => 'Ezr.',
      'Neh' => 'Neh.', 'Esth' => 'Esth.', 'Job' => 'Job', 'Ps' => 'Ps.', 'Prov' => 'Prov.',
      'Eccl' => 'Eccl.', 'Song' => 'Song', 'Isa' => 'Isa.', 'Jer' => 'Jer.', 'Lam' => 'Lam.',
      'Ezek' => 'Ezek.', 'Dan' => 'Dan.', 'Hos' => 'Hos.', 'Joel' => 'Joel', 'Amos' => 'Amos',
      'Obad' => 'Obad.', 'Jonah' => 'Jonah', 'Mic' => 'Mic.', 'Nah' => 'Nah.', 'Hab' => 'Hab.',
      'Zeph' => 'Zeph.', 'Hag' => 'Hag.', 'Zech' => 'Zech.', 'Mal' => 'Mal.',
      'Tob' => 'Tobit', 'Jdt' => 'Judith', 'Wis' => 'Wisdom', 'Sir' => 'Sir.', 'Bar' => 'Bar.',
      '1Macc' => '1 Mac.', '2Macc' => '2 Mac.', '3Macc' => '3 Mac.',
      'Matt' => 'Matt.', 'Mark' => 'Mark', 'Luke' => 'Luke', 'John' => 'John', 'Acts' => 'Acts',
      'Rom' => 'Rom.', '1Cor' => '1 Cor.', '2Cor' => '2 Cor.', 'Gal' => 'Gal.', 'Eph' => 'Eph.',
      'Phil' => 'Phil.', 'Col' => 'Col.', '1Thess' => '1 Thess.', '2Thess' => '2 Thess.',
      '1Tim' => '1 Tim.', '2Tim' => '2 Tim.', 'Titus' => 'Titus', 'Phlm' => 'Phlm.', 'Heb' => 'Heb.',
      'Jas' => 'Jas.', '1Pet' => '1 Pet.', '2Pet' => '2 Pet.', '1John' => '1 John', '2John' => '2 John',
      '3John' => '3 John', 'Jude' => 'Jude', 'Rev' => 'Rev.',
    }.freeze

    # Слова, которые могут стоять в сноске рядом со ссылками, не превращая её в комментарий
    REF_NOTE_WORDS = /\b(?:comp|compare|cf|see|and|also|etc|sq|seq|ff|ver|vers|ver?ses?)\b\.?/i

    # Эти элементы со всем содержимым выбрасываем
    DROP = %w[index insertIndex scripCom pb img hr ThML.head name attr].freeze
    # Эти переносим как есть (содержимое обрабатываем)
    KEEP = %w[i b em strong sup ul ol li table tr td th].freeze
    HEADINGS = %w[h1 h2 h3 h4 h5 h6].freeze

    # Заголовки разделов, написанных составителями и переводчиками, а не древним автором
    EDITORIAL = /\A(?:
      elucidations? | introductory\ (?:note|notice).* | translator['’]?s\ .* | (?:general\ |additional\ )?notes?
      | .*\bnotes?\ by\ (?:the\ )?.*(?:editor|translator).* | dr\.\ holmes['’]?\ note | preliminary\ notes?\ .*
      | additional\ notes?\ on\ .* | note\ on\ the\ following\ work | excursus\b.* | index
      | title\ pages? | (?:table\ of\ )?contents\b.* | advertisement
      | preface\ to\ .* | introductory\ essay\b.* | (?:general\ |special\ )?prolegomena\b.*
      | testimonies\ of\ the\ ancients\b.* | historical\ (?:introduction|excursus|note)\b.* | general\ introduction
      | introduction\ on\ .* | note\ on\ .* | examination\ of\ the\ caroline\ books | prefatory\ note | supplementary\ notes\b.* | chronological\ tables?\b.* | manuscripts\ and\ editions\b.*
    )\.?\z/xi

    def self.call(div, **opts) = new(**opts).render(div)

    def self.editorial?(title) = EDITORIAL.match?(title.to_s.strip)

    CHAPTER = /\A(?:chapter|chap\.)\s*(?<num>[IVXLCDM]+|\d+)\b\.?\s*(?:[—–\-:]+\s*)?(?<rest>.*)\z/i
    ROMAN = { 'M' => 1000, 'D' => 500, 'C' => 100, 'L' => 50, 'X' => 10, 'V' => 5, 'I' => 1 }.freeze

    # "Chapter IV.—Praise of the Ephesians." -> "4. Praise of the Ephesians.", "Chap. XII." -> "12"
    def self.short_title(title)
      m = CHAPTER.match(title.to_s.strip) or return title
      num = m[:num] =~ /\A\d+\z/ ? m[:num].to_i : roman_to_i(m[:num])
      m[:rest].empty? ? num.to_s : "#{num}. #{m[:rest]}"
    end

    def self.roman_to_i(str)
      values = str.upcase.chars.map { ROMAN.fetch(_1) }
      values.each_with_index.sum { |v, i| values[i + 1].to_i > v ? -v : v }
    end

    # depth       - уровень заголовка для подразделов первого уровня (2 => h2)
    # skip_ids    - id подразделов, которые не берём (кроме тех, что отсеиваются по EDITORIAL)
    # skip_titles - заголовки подразделов, которые не берём (в томе это всегда текст составителя)
    # cut_after   - абзац-заголовок (например "Notes."), после которого до конца раздела идут комментарии составителя
    def initialize(depth: 2, skip_ids: [], skip_titles: [], cut_after: nil)
      @depth = depth
      @skip_ids = skip_ids
      @skip_titles = skip_titles.map { norm(_1) }
      @cut_after = cut_after && norm(cut_after)
    end

    def skip?(node) = self.class.editorial?(::Ccel::Volume.title_of(node)) || @skip_ids.include?(node['id']) ||
                      @skip_titles.include?(norm(::Ccel::Volume.title_of(node)))

    def render(div)
      @notes = []
      @titles = []
      add_title(::Ccel::Volume.title_of(div))
      drop_title_page(div, is_root: true)
      body = blocks(div, @depth).join.gsub(/ {2,}/, ' ').gsub(%r{(<(?:p|h\d|li)>) }, '\1')
      Result.new(body: body, notes: @notes, pages: ::Ccel::Volume.page_range(div))
    end

    private

    # Название раздела запоминаем целиком и без "Chapter IV.—": абзац с ним в начале раздела - повтор заголовка
    def add_title(title)
      @titles << title_key(title)
      m = CHAPTER.match(title.to_s.strip)
      @titles << title_key(m[:rest]) if m && m[:rest].present?
    end

    # "The Apology." и "Apology" - одно название
    def title_key(str) = norm(str).sub(/\Athe /, '')

    RULE_LINE = /\A[\s—–\-_*·.]{3,}\z/

    # Титульный лист, набранный абзацами в начале раздела ("the homilies of st. john chrysostom, / archbishop of
    # constantinople, / on the ... / ————"): короткие абзацы до первого вложенного раздела или длинного абзаца.
    # Убираем всё до строки-разделителя "————" включительно, а в корне труда - и просто 3+ коротких абзаца подряд
    def drop_title_page(div, is_root: false)
      lead = div.element_children.take_while { |el| !::Ccel::Volume.div?(el) && (el.name != 'p' || el.text.strip.size < 150) }
      rule = lead.rindex { _1.name == 'p' && _1.text.strip.match?(RULE_LINE) }
      if rule
        lead[0..rule].each(&:remove)
      elsif is_root && lead.count { _1.name == 'p' } >= 3
        lead.select { _1.name == 'p' }.each(&:remove)
      end
    end

    # Блочный уровень: раздел -> массив HTML-блоков
    def blocks(el, level)
      is_started = false
      is_cut = false
      el.children.flat_map do |node|
        next [] unless node.element?
        name = node.name
        # после маркера комментариев берём только вложенные разделы
        next [] if is_cut && !::Ccel::Volume.div?(node)
        if @cut_after && name == 'p' && norm(node.text) == @cut_after
          is_cut = true
          next []
        end
        # заголовок (или абзац с названием) в самом начале раздела - это его название, оно уже есть в h2-h4 или в title
        next [] if !is_started && HEADINGS.include?(name)
        next [] if !is_started && name == 'p' && @titles.include?(title_key(text_without_notes(node)))
        is_started = true unless DROP.include?(name)

        if ::Ccel::Volume.div?(node)
          title = ::Ccel::Volume.title_of(node)
          next [] if skip?(node)
          add_title(title)
          drop_title_page(node)
          h = "h#{[level, 4].min}"
          [(title.present? ? "<#{h}>#{esc(self.class.short_title(title))}</#{h}>" : nil), *blocks(node, level + 1)].compact
        elsif name == 'div'
          blocks(node, level)
        elsif HEADINGS.include?(name)
          # заголовок в тексте, который повторяет название раздела, не нужен: он уже есть в h2-h4
          text = inline(node)
          next [] if text.blank? || @titles.include?(title_key(text_without_notes(node)))
          ["<p><strong>#{text}</strong></p>"]
        elsif name == 'p'
          text = inline(node).strip
          text.present? ? ["<p>#{text}</p>"] : []
        elsif name == 'verse'
          lines = node.xpath('.//l').map { inline(_1).strip }.reject(&:blank?)
          lines.any? ? ["<blockquote>#{lines.map { "<p>#{_1}</p>" }.join}</blockquote>"] : []
        elsif %w[ul ol table].include?(name)
          ["<#{name}>#{inline(node)}</#{name}>"]
        elsif DROP.include?(name)
          []
        else
          text = inline(node).strip
          text.present? ? ["<p>#{text}</p>"] : []
        end
      end
    end

    # Строчный уровень: элемент -> HTML без блочных тегов
    def inline(el)
      el.children.map do |node|
        if node.text?
          esc(node.text.gsub(/\s+/, ' '))
        elsif !node.element? || DROP.include?(node.name)
          ''
        elsif node.name == 'note'
          note(node)
        elsif node.name == 'scripRef'
          esc(scrip_ref(node))
        elsif node.name == 'br'
          ' '
        elsif node.name == 'p' || node.name == 'l'
          " #{inline(node).strip} "
        elsif KEEP.include?(node.name)
          tag = node.name
          inner = inline(node)
          %w[ul ol table tr].include?(tag) || inner.present? ? "<#{tag}>#{inner}</#{tag}>" : ''
        else
          inline(node)
        end
      end.join
    end

    def note(node)
      html = inline(node).gsub(/\s+/, ' ').strip
      return '' if html.blank?

      if ref_only?(node)
        # "Comp. 1 Cor. 16:18, etc." -> " (comp. 1 Cor. 16:18)"
        text = html.sub(/[\s.,;]+\z/, '').sub(/,?\s*etc\z/i, '')
        text = text[0].downcase + text[1..] if text =~ /\A(?:Comp|Cf|See|Compare)\b/
        " (#{text})"
      else
        @notes << html
        "[#{@notes.size}]"
      end
    end

    # В сноске только ссылки на Писание (и связки вроде "comp.", "and", "etc.")?
    def ref_only?(node)
      return false unless node.at_xpath('.//scripRef')
      rest = node.dup
      rest.xpath('.//scripRef').each(&:remove)
      rest.text.gsub(REF_NOTE_WORDS, '').match?(/\A[\s.,;:()\[\]–—\-]*\z/)
    end

    # parsed="|1Pet|5|1|5|5;|Prov|9|17|0|0" -> "1 Pet. 5:1–5; Prov. 9:17"
    def scrip_ref(node)
      parsed = node['parsed'].to_s.split(';').map { _1.split('|').drop(1) }
      refs = parsed.map { |book, ch, v, ch2, v2| format_ref(book, ch.to_i, v.to_i, ch2.to_i, v2.to_i) }
      return node.text.gsub(/\s+/, ' ') if refs.empty? || refs.any?(&:nil?)
      refs.join('; ')
    end

    def format_ref(book, ch, v, ch2, v2)
      abbr = BOOK_ABBR[book] or return
      return "#{abbr} #{ch}" if v.zero?
      return "#{abbr} #{ch}:#{v}" if ch2.zero? || (ch2 == ch && v2 <= v)
      return "#{abbr} #{ch}:#{v}–#{v2}" if ch2 == ch
      "#{abbr} #{ch}:#{v}–#{ch2}:#{v2}"
    end

    def esc(str) = ::ERB::Util.html_escape(str)

    def text_without_notes(node) = node.xpath('.//text()[not(ancestor::note)]').map(&:text).join

    def norm(str) = str.to_s.downcase.gsub(/[^\p{L}\d]+/, ' ').strip
  end
end
