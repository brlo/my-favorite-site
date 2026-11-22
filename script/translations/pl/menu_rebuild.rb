# Перестройка меню латинских авторов по конфигам конвейера (authors/*.json):
#  - папки — как в конфиге (Dogmatica, Exegetica, Sermones, …);
#  - труд из нескольких страниц получает свою подпапку, а пункты внутри — только
#    обозначение части («Liber 1», «Libri 3–4», «1/2»), без повторения названия труда;
#  - одиночный труд — один пункт с коротким названием (римские цифры → арабские);
#  - пустые папки-артефакты прежних прогонов удаляются, посторонние ссылки не трогаются.
#
#   bin/rails runner script/translations/pl/menu_rebuild.rb [DRY_RUN=1] [AUTHOR=augustinus]
require 'json'

load File.expand_path('menu_tidy.rb', __dir__)

module MenuRebuild
  module_function

  def part_label(page_title, work_title)
    t = page_title.to_s.strip
    wt = work_title.to_s.strip
    if t.include?(',') && wt.present? && t.split(',').first.strip[0, 12].to_s.downcase == wt[0, 12].to_s.downcase
      t = t.split(',', 2).last
    elsif wt.present? && t.downcase.start_with?(wt.downcase)
      t = t[wt.length..]
    end
    t = t.sub(/\A[,\s–—-]+/, '').strip
    if (m = t.match(/\A\((\d+\s*\/\s*\d+)\)\z/))
      t = m[1]
    end
    MenuTidy.convert(t)
  end

  # название труда для подпапки: без «Tractatus CXXIV» в хвосте
  def display_title(work_title)
    t = work_title.to_s.strip
    t = t.sub(/\s+Tractatus\s+[0-9IVXLC]+\s*\z/i, '')
    t = t.sub(/\s+(Libri|Liber)\s+[0-9IVXLC]+\s*\z/i, '')
    MenuTidy.convert(t)
  end

  def short_title(work_title, folder_title)
    t = work_title.to_s.strip
    f = folder_title.to_s.strip
    if f.present? && t.downcase.start_with?(f.downcase)
      rest = t[f.length..].sub(/\A[,\s–—-]+/, '').strip
      return MenuTidy.convert(rest) if rest.present?
    end
    if f.casecmp?('Enarrationes in Psalmos') && (m = t.match(/\AEnarratio(?:nes)? in Psalm(?:um|os)\s+(.+)\z/i))
      return MenuTidy.convert(m[1])
    end
    MenuTidy.convert(t)
  end

  # рабочее название труда: из конфига или из заголовка первой части
  def work_title(w)
    t = w['title'].to_s.strip
    return t if t.present?
    first = w.dig('parts', 0, 'title').to_s.strip
    return '' if first.empty?
    first.include?(',') ? first.split(',').first.strip : first.sub(/\s+(Liber|Libri|Tractatus)\b.*/, '')
  end

  def pages_for(base, pages_by_path)
    key = base.to_s.downcase
    list = []
    list << pages_by_path[key] if pages_by_path[key]
    pages_by_path.each do |k, p|
      list << p if k.start_with?("#{key}_")
    end
    list.compact.uniq.sort_by(&:id)
  end

  def run!(files, dry: false)
    files.each do |file|
      next unless File.exist?(file)
      cfg = JSON.parse(File.read(file))
      rebuild(cfg, dry: dry)
    end
  end

  def rebuild(cfg, dry: false)
    lang = cfg['lang'] || 'la'
    apath = cfg.dig('author', 'path') or return
    author = ::Page.find_by(lang: lang, path_low: apath.downcase)
    return puts("! нет автора #{apath}") unless author
    puts "== #{author.title}"
    pages_by_path = ::Page.where(lang: lang, parent_id: author.id).to_a
                         .each_with_object({}) { |p, h| h[p.path.downcase] = p }

    works = cfg['works'].map do |w|
      bases = w['parts'] ? w['parts'].map { |pt| pt['path'] } : [w['path']]
      pages = bases.flat_map { |b| pages_for(b, pages_by_path) }
      [w, pages]
    end.reject { |_w, pages| pages.empty? }
        .sort_by { |w, pages| [w['volume'].to_i, w['priority'].to_i, pages.first.id] }

    # 1. голые заголовки страниц («Liber PRIMUS») получают название труда
    works.each do |w, pages|
      wt = work_title(w)
      pages.each do |p|
        next unless p.title.to_s.match?(/\A(Liber|Libri|Tractatus)\b/)
        next if wt.present? && p.title.to_s.downcase.include?(wt[0, 12].downcase)
        new_title = "#{wt}, #{p.title}"
        if dry
          puts "  страница #{p.path}: #{p.title.inspect} → #{new_title.inspect}"
        else
          p.update!(title: new_title)
        end
      end
    end

    # 2. папки
    folder_menus = {}
    cfg.fetch('folders', []).each_with_index do |f, i|
      next if dry
      folder_menus[f['title']] =
        ::Menu.where(page_id: author.id, parent_id: nil, title: f['title']).first ||
        ::Menu.create!(page_id: author.id, parent_id: nil, title: f['title'], path: nil,
                       is_empty: false, priority: i + 1)
    end

    # 3. пункты
    counter = Hash.new(0)
    works.each do |w, pages|
      folder = dry ? nil : folder_menus[w['folder']]
      if pages.size > 1
        sub_title = display_title(work_title(w))
        sub = nil
        counter[w['folder']] += 1
        prio = counter[w['folder']]
        unless dry
          sub = ::Menu.where(page_id: author.id, parent_id: folder&.id, title: sub_title, path: [nil, '']).first
          sub ||= ::Menu.create!(page_id: author.id, parent_id: folder&.id, title: sub_title, path: nil,
                                 is_empty: false, priority: prio)
          sub.update!(title: sub_title, priority: prio)
        end
        pages.each_with_index do |p, idx|
          label = part_label(p.title, work_title(w)).presence || (idx + 1).to_s
          if dry
            puts "    #{sub_title} / #{label}  (#{p.path})"
          else
            m = ::Menu.where(page_id: author.id, path: p.path).first
            m ||= ::Menu.create!(page_id: author.id, title: label, path: p.path, is_empty: false, priority: idx + 1)
            m.update!(parent_id: sub.id, title: label, priority: idx + 1)
          end
        end
      else
        p = pages.first
        label = short_title(work_title(w), w['folder'])
        if dry
          puts "  #{w['folder']} / #{label}  (#{p.path})"
        else
          m = ::Menu.where(page_id: author.id, path: p.path).first
          m ||= ::Menu.create!(page_id: author.id, title: label, path: p.path, is_empty: false, priority: 1)
          m.update!(parent_id: folder&.id, title: label, priority: (counter[w['folder']] += 1))
        end
      end
    end

    # 4. удалить опустевшие папки, которых нет в конфиге
    return if dry
    keep = cfg.fetch('folders', []).map { |f| f['title'] }
    ::Menu.where(page_id: author.id, path: [nil, '']).where.not(title: keep).to_a.each do |m|
      next unless ::Menu.where(parent_id: m.id).count.zero?
      puts "    удалена пустая папка «#{m.title}»"
      m.destroy!
    end
  end
end

files = Dir[File.expand_path('authors/*.json', __dir__)]
if ENV['AUTHOR'].present?
  files = files.select { |f| File.basename(f, '.json') == ENV['AUTHOR'] }
end
MenuRebuild.run!(files.sort, dry: ENV['DRY_RUN'].present?)
