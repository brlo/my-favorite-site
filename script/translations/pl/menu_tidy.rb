# Упрощение меню латинских авторов:
#  - части труда больше не повторяют название труда, если оно уже в родительской папке
#    («Enarrationes in Psalmos II–VII» → «1–7»), для многотомных трудов создаётся
#    своя подпапка («De Civitate Dei» → «Liber 1», «Liber 2», …);
#  - римские цифры и слова PRIMUS–VIGESIMUS SECUNDUS заменяются арабскими.
#
# Запуск (см. menu_tidy_run.rb):
#   bin/rails runner script/translations/pl/menu_tidy_run.rb
#   DRY_RUN=1 bin/rails runner script/translations/pl/menu_tidy_run.rb
#   AUTHOR=UoFc_... bin/rails runner script/translations/pl/menu_tidy_run.rb
#
# Повторный прогон безопасен: уже созданные подпапки переиспользуются.

module MenuTidy
  ROMAN_VALS = { 'I' => 1, 'V' => 5, 'X' => 10, 'L' => 50, 'C' => 100 }

  WORDS = {
    'PRIMUS' => 1, 'SECUNDUS' => 2, 'TERTIUS' => 3, 'QUARTUS' => 4, 'QUINTUS' => 5,
    'SEXTUS' => 6, 'SEPTIMUS' => 7, 'OCTAVUS' => 8, 'NONUS' => 9, 'DECIMUS' => 10,
    'UNDECIMUS' => 11, 'DUODECIMUS' => 12,
    'TERTIUS DECIMUS' => 13, 'DECIMUS TERTIUS' => 13, 'QUARTUS DECIMUS' => 14,
    'DECIMUS QUARTUS' => 14, 'QUINTUS DECIMUS' => 15, 'DECIMUS QUINTUS' => 15,
    'SEXTUS DECIMUS' => 16, 'DECIMUS SEXTUS' => 16, 'SEPTIMUS DECIMUS' => 17,
    'DECIMUS SEPTIMUS' => 17, 'OCTAVUS DECIMUS' => 18, 'DECIMUS OCTAVUS' => 18,
    'NONUS DECIMUS' => 19, 'DECIMUS NONUS' => 19, 'VIGESIMUS' => 20,
    'VIGESIMUS PRIMUS' => 21, 'VIGESIMUS SECUNDUS' => 22, 'VIGESIMUS TERTIUS' => 23,
    'TRICESIMUS' => 30, 'TRICESIMUS TERTIUS' => 33
  }.freeze

  KEYWORDS = %w[Liber Libri Caput Capitulum Collatio Epistola Epistolae Tractatus Sermo Sermones
                Psalmus Psalmum Enarratio Inscriptio].freeze

  module_function

  def roman_to_i(str)
    total = 0
    prev = 0
    str.to_s.upcase.reverse.each_char do |ch|
      v = ROMAN_VALS[ch] or return nil
      total += v < prev ? -v : v
      prev = [prev, v].max
    end
    total
  end

  def valid_roman?(str)
    s = str.to_s.upcase
    return false if s.empty? || s.length > 12 || !s.match?(/\A[IVXLC]+\z/)
    roman_to_i(s).positive?
  end

  # «LIBER SEXTUS DECIMUS» → «Liber 16», «Enarrationes II–VII» → «Enarrationes 2–7»
  def convert(title)
    t = title.to_s.strip
    WORDS.sort_by { |k, _| -k.length }.each do |word, num|
      t = t.gsub(/\b#{Regexp.escape(word)}\b/i, num.to_s)
    end
    t = t.gsub(/\b(#{KEYWORDS.join('|')})\s+([IVXLC]+)(\s*[–-]\s*([IVXLC]+))?/) do
      head, from, dash, to = Regexp.last_match(1), Regexp.last_match(2), Regexp.last_match(3), Regexp.last_match(4)
      out = "#{head} #{roman_to_i(from)}"
      out += "#{dash.to_s[/[\u2013-]/]}#{roman_to_i(to)}" if to
      out
    end
    t = t.gsub(/([IVXLC]+)\s*([–-])\s*([IVXLC]+)/) do
      a, dash, b = Regexp.last_match(1), Regexp.last_match(2), Regexp.last_match(3)
      valid_roman?(a) && valid_roman?(b) ? "#{roman_to_i(a)}#{dash}#{roman_to_i(b)}" : "#{a}#{dash}#{b}"
    end
    t = t.gsub(/\(([IVXLC]+)\)/) { valid_roman?(Regexp.last_match(1)) ? "(#{roman_to_i(Regexp.last_match(1))})" : Regexp.last_match(0) }
    t = t.gsub(/\A([IVXLC]+)(?=[\s.,;:)]|\z)/) { valid_roman?(Regexp.last_match(1)) ? roman_to_i(Regexp.last_match(1)).to_s : Regexp.last_match(0) }
    t = t.gsub(/([IVXLC]+)\z/) { valid_roman?(Regexp.last_match(1)) ? roman_to_i(Regexp.last_match(1)).to_s : Regexp.last_match(0) }
    # оставшиеся отдельные римские токены (LXXXIII, CXXIV) — тоже в арабские
    { 'LIBER' => 'Liber', 'LIBRI' => 'Libri', 'TRACTATUS' => 'Tractatus', 'SERMO' => 'Sermo',
      'SERMONES' => 'Sermones', 'EPISTOLA' => 'Epistola', 'EPISTOLAE' => 'Epistolae',
      'PSALMUS' => 'Psalmus', 'CAPUT' => 'Caput' }.each { |up, normal| t = t.gsub(/\b#{up}\b/, normal) }
    t = t.gsub(/\b([IVXLC]{2,})\b/) do
      s = Regexp.last_match(1)
      n = valid_roman?(s) ? roman_to_i(s) : nil
      n && n <= 300 ? n.to_s : s
    end
    t.gsub(/\s+/, ' ').strip
  end

  PART_RE = /\A(.+?),\s*(Libri|Liber|Tractatus|Epistolae|Epistola|Sermones|Sermo|Capitula|Partes)\b/
  PAREN_RE = /\A(.+?)\s*\((\d+\s*\/\s*\d+)\)\z/

  # → [название труда, обозначение части]
  def split_title(title, folder_title)
    t = title.to_s.strip
    folder = folder_title.to_s.strip

    if (m = t.match(PAREN_RE))
      return [m[1], m[2]]
    end
    if (m = t.match(PART_RE))
      return [m[1], t[m.begin(2)..].strip]
    end
    if folder.present?
      if t.downcase.start_with?(folder.downcase)
        rest = t[folder.length..].sub(/\A[,:–—-]\s*/, '').strip
        return [folder, rest] if rest.match?(/\A[\dIVXLC]/) || rest.match?(/\A(Libri|Liber|Tractatus|Sermones|Sermo|Epistolae|Epistola)\b/)
      end
      # «Enarratio in Psalmum LXXIX» при папке «Enarrationes in Psalmos»
      if folder.casecmp?('Enarrationes in Psalmos') && (m = t.match(/\AEnarratio(?:nes)? in Psalm(?:um|os)\s*(.+)\z/i))
        return [folder, m[1]]
      end
      # «Epistola 130» при папке «Epistolae»
      if folder.casecmp?('Epistolae') && (m = t.match(/\AEpistola\s+(.+)\z/i))
        return [folder, m[1]]
      end
      # «Collatio IX. De Oratione» при папке «Collationes»
      if folder.casecmp?('Collationes') && (m = t.match(/\ACollatio\s+(.+)\z/i))
        return [folder, m[1]]
      end
    end

    [t, '']
  end

  def page_for(menu)
    @pages ||= {}
    key = menu.path.to_s.downcase
    return @pages[key] if @pages.key?(key)
    @pages[key] = ::Page.where(lang: 'la', path_low: key).first
  end

  def page_title(menu)
    page_for(menu)&.title
  end

  # порядок — как страницы импортированы (id), иначе priority чередует тома
  def sort_key(menu)
    [page_for(menu)&.id || 10**9, menu.priority.to_i, menu.id]
  end

  def tidy_author(author, dry: false)
    items = ::Menu.where(page_id: author.id).to_a
    folders = items.select { |m| m.parent_id.nil? && m.path.blank? }
    folders.each { |f| tidy_folder(f, items, dry: dry) }
    root_links = items.select { |m| m.parent_id.nil? && m.path.present? }
    tidy_folder(nil, items, dry: dry) if root_links.any?
  end

  def tidy_folder(folder, items, dry: false)
    children = items.select { |m| m.parent_id == folder&.id }
    subs = children.select { |m| m.path.blank? }
    links = children.select { |m| m.path.present? }

    puts "  папка «#{folder&.title || '(без папки)'}»: #{links.size} пунктов" if dry

    subs.each do |sf|
      title = convert(sf.title)
      update(sf, { title: title }, dry) unless sf.title == title
      sf_children = items.select { |m| m.parent_id == sf.id }.sort_by { |m| sort_key(m) }
      sf_children.each_with_index do |ch, idx|
        title = page_title(ch) || ch.title
        label = strip_work_prefix(title, sf.title)
        label = convert(title) if label.blank?
        update(ch, { title: label, priority: idx + 1 }, dry)
      end
    end

    groups = links.group_by do |m|
      title = page_title(m) || m.title
      split_title(title, folder&.title).first
    end

    groups.sort_by { |_base, ms| ms.map { |m| sort_key(m) }.min }.each do |base, ms|
      base_conv = convert(base)
      ordered = ms.sort_by { |m| sort_key(m) }
      folder_matches = base_conv.casecmp?(folder&.title.to_s)

      if ordered.size >= 2 && !folder_matches
        sub = subs.find { |sf| sf.title.casecmp?(base_conv) }
        if dry
          puts "    подпапка «#{base_conv}»:"
          subs_list = subs.map(&:title)
          puts "    (уже есть: #{subs_list.join(', ')})" if subs_list.any?
        else
          sub ||= ::Menu.create!(page_id: folder&.page_id || ordered.first.page_id, parent_id: folder&.id,
                                 title: base_conv, path: nil, is_empty: false,
                                 priority: (subs.map { |s| s.priority.to_i }.max || 0) + 1)
        end
        ordered.each_with_index do |m, idx|
          title = page_title(m) || m.title
          _b, label = split_title(title, folder&.title)
          label = convert(label)
          label = base_conv if label.blank?
          puts "      #{m.title} → «#{label}»" if dry
          update(m, { parent_id: (sub&.id || -1), title: label, priority: idx + 1 }, dry)
        end
      else
        ordered.each_with_index do |m, idx|
          title = page_title(m) || m.title
          _b, label = split_title(title, folder&.title)
          new_title = if folder_matches
                        convert(label).presence || convert(base)
                      elsif ordered.size == 1
                        convert(title)
                      else
                        convert(label).presence || convert(title)
                      end
          update(m, { parent_id: folder&.id, title: new_title, priority: idx + 1 }, dry)
        end
      end
    end
  end

  def update(menu, attrs, dry)
    changes = attrs.reject { |k, v| menu.public_send(k) == v }
    return if changes.empty?
    if dry
      puts "  [#{menu.id}] #{changes.map { |k, v| "#{k}: #{menu.public_send(k).inspect} → #{v.inspect}" }.join(', ')}"
    else
      menu.update!(changes)
    end
  end

  def common_prefix(a, b)
    la = a.to_s.downcase
    lb = b.to_s.downcase
    n = 0
    n += 1 while n < la.length && n < lb.length && la[n] == lb[n]
    n
  end

  def strip_work_prefix(title, work_title)
    t = title.to_s.strip
    wt = work_title.to_s.strip
    if wt.present? && t.downcase.start_with?(wt.downcase)
      t = t[wt.length..]
    elsif wt.present? && (n = common_prefix(t, wt)) >= 8
      t = t[n..]
    end
    convert(t.sub(/\A[,\s–—-]+/, '').strip)
  end

  # нормализация уже существующих пунктов меню у всех латинских авторов (без перестроения)
  def normalize_titles!(lang: 'la', list_path: 'church_writers_la', dry: false)
    list = ::Page.find_by(lang: lang, path_low: list_path.downcase) or return
    ::Page.where(lang: lang, parent_id: list.id, page_type: 4).find_each do |author|
      ::Menu.where(page_id: author.id).where.not(path: [nil, '']).find_each do |m|
        new_title = convert(m.title)
        next if new_title == m.title
        if dry
          puts "  [#{m.id}] #{m.title.inspect} → #{new_title.inspect}"
        else
          m.update!(title: new_title)
        end
      end
    end
  end

  def run!(lang: 'la', list_path: 'church_writers_la', dry: false, author_path: nil, skip_paths: [])
    list = ::Page.find_by(lang: lang, path_low: list_path.downcase)
    return puts("нет списка #{list_path}") unless list

    scope = ::Page.where(lang: lang, parent_id: list.id, page_type: 4)
    scope = scope.where(path_low: author_path.downcase) if author_path
    skip = skip_paths.map(&:downcase)
    scope = scope.where.not(path_low: skip) if skip.any?
    scope.order(:id).each do |author|
      puts "== #{author.title}"
      tidy_author(author, dry: dry)
    end
  end
end

