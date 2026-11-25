# frozen_string_literal: true

# Меню самой страницы автора: links_XX → раздел → автор → труды.
#
# Импорт (`pages:import_translations`) кладёт труды в меню страницы-списка
# (page_id = список). Страница автора строит своё дерево из пунктов с
# page_id = автор, поэтому без этого шага на странице автора нет ссылок на
# труды — только «Похожие материалы». Скрипт переносит труды из меню списка
# в меню автора (категория + труды) и удаляет дубли из меню списка.
#
#   bin/rails runner script/translations/author_menus.rb                    # все из CONFIG
#   bin/rails runner script/translations/author_menus.rb ONLY_LANG=de       # только de
#   bin/rails runner script/translations/author_menus.rb DRY_RUN=1          # план
#
# Идемпотентен. Новым партиям: добавьте автора в CONFIG
# (язык → путь автора → название категории).

CONFIG = {
  'de' => {
    'Klemens_von_Rom' => 'Briefe',
    'Ignatius_von_Antiochien' => 'Briefe',
    'Polykarp_von_Smyrna' => 'Briefe',
  },
  'fr' => {
    'Théophile_d_Antioche' => 'Œuvres apologétiques',
  },
}.freeze

only_lang = ARGV.find { |arg| arg.start_with?('ONLY_LANG=') }&.sub('ONLY_LANG=', '')
is_dry_run = ARGV.include?('DRY_RUN=1') || ENV['DRY_RUN'].present?

CONFIG.each do |lang, authors|
  next if only_lang && only_lang != lang

  authors.each do |author_path, category_title|
    author = ::Page.find_by(lang: lang, path: author_path)
    unless author
      puts "#{lang}/#{author_path}: нет страницы автора"
      next
    end

    list = author.parent
    item = ::Menu.find_by(page_id: list&.id, path: author.path)
    unless item
      puts "#{lang}/#{author_path}: автор не найден в меню списка #{list&.path.inspect}"
      next
    end

    list_works = ::Menu.where(page_id: list.id, parent_id: item.id).where.not(path: [nil, '']).order(:priority)
    if list_works.empty?
      puts "#{lang}/#{author_path}: под автором в меню списка нет трудов — пропуск"
      next
    end

    author_works = ::Menu.where(page_id: author.id).where.not(path: [nil, '']).pluck(:path)
    if author_works.empty?
      if is_dry_run
        puts "[DRY RUN] #{lang}/#{author_path}: категория «#{category_title}» + #{list_works.size} трудов, дубли из меню списка — удалить"
        next
      end

      ::ActiveRecord::Base.transaction do
        category = ::Menu.create!(page_id: author.id, title: category_title, priority: 1)
        list_works.each_with_index do |work, index|
          ::Menu.create!(
            page_id: author.id,
            parent_id: category.id,
            title: work.title,
            path: work.path,
            priority: work.priority.presence || index + 1,
          )
        end
      end
      author_works = list_works.map(&:path)
      puts "#{lang}/#{author_path}: категория «#{category_title}» + #{list_works.size} трудов"
    end

    # в меню списка труды не нужны: они живут на странице автора
    dupes = ::Menu.where(page_id: list.id, parent_id: item.id, path: author_works)
    next if dupes.empty?

    count = dupes.count
    if is_dry_run
      puts "[DRY RUN] #{lang}/#{author_path}: удалить дублей из меню списка: #{count}"
    else
      dupes.destroy_all
      puts "#{lang}/#{author_path}: удалено дублей из меню списка: #{count}"
    end
  end
end
