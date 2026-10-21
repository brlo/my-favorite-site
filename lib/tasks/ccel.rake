# Импорт трудов святых отцов из CCEL (ANF, NPNF): https://ccel.org/
# XML-файлы томов (anf01.xml ... npnf214.xml) кладём в tmp/ccel (или указываем DIR=...).
namespace :ccel do
  desc 'Загрузить труды по карте: MAP=db/ccel_map.yml DIR=tmp/ccel ONLY=anf01,anf02 DRY_RUN=1'
  task import: :environment do
    importer = ::Ccel::Importer.new(
      ENV.fetch('MAP', 'db/ccel_map.yml'),
      dir: ENV.fetch('DIR', 'tmp/ccel'),
      only: ENV['ONLY'].presence&.split(','),
      is_dry_run: ENV['DRY_RUN'].present?,
    )
    stats = importer.run
    puts "#{'[DRY RUN] ' if ENV['DRY_RUN'].present?}Создано: #{stats[:created]}, обновлено: #{stats[:updated]}, пропущено (уже есть): #{stats[:skipped]}, новых авторов: #{stats[:authors]}"
  end

  desc 'Удалить загруженные страницы, которых больше нет в карте: MAP=db/ccel_map.yml DIR=tmp/ccel [DRY_RUN=1]'
  task prune: :environment do
    is_dry_run = ENV['DRY_RUN'].present?
    importer = ::Ccel::Importer.new(ENV.fetch('MAP', 'db/ccel_map.yml'), dir: ENV.fetch('DIR', 'tmp/ccel'))
    log = importer.prune(is_dry_run:)
    puts log.map { "#{'[DRY RUN] ' if is_dry_run}удалено: #{_1}" }
    puts "#{'[DRY RUN] ' if is_dry_run}Всего: #{log.size}"
  end

  desc 'Оглавление томов с размерами разделов: tmp/ccel/outline/<том>.txt (нужно для составления карты импорта)'
  task inventory: :environment do
    dir = ENV.fetch('DIR', 'tmp/ccel')
    out_dir = ::File.join(dir, 'outline')
    ::FileUtils.mkdir_p(out_dir)

    codes = ENV['ONLY'].presence&.split(',') || ::Dir[::File.join(dir, '*.xml')].map { ::File.basename(_1, '.xml') }.sort
    codes.each do |code|
      vol = ::Ccel::Volume.load(dir, code)
      lines = ["# #{code}: #{vol.title} (#{vol.editors.join(', ')})"]
      kb_of = ->(el) { (el.text.size / 1024.0).round }
      walk = lambda do |el, depth|
        children = ::Ccel::Volume.children_divs(el)
        # мелкие подразделы (главы внутри труда) не раскрываем, а только считаем
        is_expand = children.any? && (depth < 1 || children.any? { kb_of.(_1) >= 15 })
        author = ::Ccel::Volume.ccel_author_of(el)
        pages = ::Ccel::Volume.page_range(el).join('-')
        lines << "#{'  ' * depth}#{el['id']} | #{::Ccel::Volume.title_of(el)} | #{kb_of.(el)}kb | p.#{pages}" \
                 "#{" | +#{children.size} subdivs" if children.any? && !is_expand}#{" | @#{author}" if author}"
        children.each { walk.(_1, depth + 1) } if is_expand
      end
      ::Ccel::Volume.children_divs(vol.doc.at_xpath('//ThML.body')).each { walk.(_1, 0) }
      ::File.write(::File.join(out_dir, "#{code}.txt"), lines.join("\n") + "\n")
      puts "#{code}: #{lines.size - 1} разделов"
    end
  end
end

namespace :pages do
  desc 'Связать существующие страницы на разных языках по списку: FILE=db/lang_links.yml [DRY_RUN=1]'
  task link_langs: :environment do
    pairs = ::YAML.load_file(ENV.fetch('FILE', 'db/lang_links.yml'))
    is_dry_run = ENV['DRY_RUN'].present?
    puts ::LangLinker.call(pairs, is_dry_run:).map { "#{'[DRY RUN] ' if is_dry_run}#{_1}" }
  end
end
