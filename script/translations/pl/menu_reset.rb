# Полный сброс меню латинских авторов и перестройка по конфигам.
# Посторонние страницы (не из конвейера) остаются в меню на прежнем месте.
#   bin/rails runner script/translations/pl/menu_reset.rb [DRY_RUN=1]
require 'json'
require_relative 'menu_rebuild'

dry = ENV['DRY_RUN'].present?
Dir[File.expand_path('authors/*.json', __dir__)].sort.each do |file|
  cfg = JSON.parse(File.read(file))
  author = ::Page.find_by(lang: cfg['lang'] || 'la', path_low: cfg.dig('author', 'path').to_s.downcase)
  next puts("! нет автора #{cfg.dig('author', 'path')}") unless author
  puts "== #{author.title}"

  pages_by_path = ::Page.where(lang: author.lang, parent_id: author.id).to_a
                       .each_with_object({}) { |p, h| h[p.path.downcase] = p }
  desired = cfg['works'].flat_map do |w|
    bases = w['parts'] ? w['parts'].map { |pt| pt['path'] } : [w['path']]
    bases.flat_map { |b| MenuRebuild.pages_for(b, pages_by_path).map { |p| p.path.downcase } }
  end

  menus = ::Menu.where(page_id: author.id).to_a
  stray = menus.select { |m| m.path.present? && !desired.include?(m.path.downcase) }
  stray_info = stray.map do |m|
    folder = menus.find { |x| x.id == m.parent_id }
    [m.path, m.title, folder&.title]
  end

  if dry
    puts "  меню: #{menus.size}, из них посторонних: #{stray_info.size}"
    stray_info.each { |p, t, f| puts "    #{f || '-'} / #{t} (#{p})" }
    next
  end

  ::Menu.where(page_id: author.id).delete_all
  MenuRebuild.rebuild(cfg, dry: false)
  stray_info.each do |path, title, folder_title|
    folder = if folder_title.present?
               ::Menu.where(page_id: author.id, parent_id: nil, title: folder_title, path: [nil, '']).first
             end
    folder ||= nil
    ::Menu.create!(page_id: author.id, parent_id: folder&.id, title: MenuTidy.convert(title), path: path,
                   is_empty: false, priority: (::Menu.where(page_id: author.id, parent_id: folder&.id).maximum(:priority).to_i + 1))
  end
  puts "  пунктов после перестройки: #{::Menu.where(page_id: author.id).count}, возвращено посторонних: #{stray_info.size}"
end
