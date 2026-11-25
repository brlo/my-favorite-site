# frozen_string_literal: true

# Перенос «прочих параметров» со страницы-эталона на перевод: обложка
# (и её оверлеи), seo_kind, is_show_parent, priority; золотые пункты меню
# (is_gold) — и в меню списка, и в меню самой страницы автора.
#
#   bin/rails runner script/translations/copy_page_meta.rb            # все из CONFIG
#   bin/rails runner script/translations/copy_page_meta.rb ONLY_LANG=de
#   bin/rails runner script/translations/copy_page_meta.rb DRY_RUN=1
#
# Идемпотентен. Новым партиям: добавьте пары «ru-путь → путь перевода»
# в CONFIG (язык → массив пар).

CONFIG = {
  'de' => [
    %w[church_writers Kirchenvaeter],
    %w[Климент_Римский Klemens_von_Rom],
    %w[Игнатий_Антиохийский Ignatius_von_Antiochien],
    %w[Поликарп_Смирнский Polykarp_von_Smyrna],
  ],
  'fr' => [
    %w[Феофил_Антиохийский Théophile_d_Antioche],
  ],
}.freeze

only_lang = ARGV.find { |arg| arg.start_with?('ONLY_LANG=') }&.sub('ONLY_LANG=', '')
is_dry_run = ARGV.include?('DRY_RUN=1') || ENV['DRY_RUN'].present?

def update_page(dst, attrs, is_dry_run)
  changed = attrs.reject { |key, value| dst.public_send(key) == value }
  return if changed.empty?

  puts "  #{dst.path}: #{changed.keys.join(', ')}"
  dst.update!(changed) unless is_dry_run
end

def copy_menu_gold(src_menu, dst_menu, is_dry_run)
  return if src_menu.nil? || dst_menu.nil? || src_menu.is_gold == dst_menu.is_gold

  puts "  меню «#{dst_menu.title}»: is_gold #{dst_menu.is_gold} -> #{src_menu.is_gold}"
  dst_menu.update!(is_gold: src_menu.is_gold, is_empty: src_menu.is_empty) unless is_dry_run
end

def translated_path(src_path, lang)
  src = ::Page.find_by(lang: 'ru', path: src_path)
  return if src.nil?

  ::Page.find_by(group_lang_id: src.group_lang_id, lang: lang)&.path
end

CONFIG.each do |lang, pairs|
  next if only_lang && only_lang != lang

  pairs.each do |src_path, dst_path|
    src = ::Page.find_by(lang: 'ru', path: src_path)
    dst = ::Page.find_by(lang: lang, path: dst_path)
    if src.nil? || dst.nil?
      puts "#{lang}: нет пары #{src_path} -> #{dst_path}"
      next
    end

    puts "#{lang}: #{src.path} -> #{dst.path}"

    # обложка: файл и оверлеи (как в TranslationImporter.copy_cover)
    if src.cover.present? && dst.cover.blank?
      puts '  cover: копируем'
      ::TranslationImporter.copy_cover(src, dst) unless is_dry_run
    end
    update_page(dst, { cover_overlay_bg: src.cover_overlay_bg, cover_overlay_text: src.cover_overlay_text }, is_dry_run)

    attrs = {
      cover_overlay_bg: src.cover_overlay_bg,
      cover_overlay_text: src.cover_overlay_text,
      is_show_parent: src.is_show_parent,
    }
    attrs[:seo_kind] = src.seo_kind if src.seo_kind.present?
    attrs[:priority] = src.priority if src.priority.present?
    update_page(dst, attrs, is_dry_run)

    # пункт в меню списка (автор/раздел)
    src_list_menu = ::Menu.find_by(page_id: src.parent_id, path: src.path)
    dst_list_menu = ::Menu.find_by(page_id: dst.parent_id, path: dst.path)
    copy_menu_gold(src_list_menu, dst_list_menu, is_dry_run)

    # место автора/раздела: папка-век в меню списка должна совпадать с RU.
    # Папки-века в разных языках имеют один и тот же priority (1 — I век, 2 — II…).
    if src_list_menu&.parent_id && dst_list_menu
      src_parent = ::Menu.find_by(id: src_list_menu.parent_id)
      if src_parent && src_parent.path.blank?
        dst_parent = ::Menu.where(page_id: dst.parent_id, path: [nil, ''])
                           .find_by(priority: src_parent.priority)
        if dst_parent && dst_list_menu.parent_id != dst_parent.id
          puts "  меню: перенос в «#{dst_parent.title}»"
          dst_list_menu.update!(parent_id: dst_parent.id) unless is_dry_run
        end
      end
    end

    # пункты в меню самой страницы (труды автора)
    next unless src.page_type.to_i == ::Page::PAGE_TYPES['список'] && dst.page_type.to_i == ::Page::PAGE_TYPES['список']

    ::Menu.where(page_id: src.id).where.not(path: [nil, '']).find_each do |src_menu|
      dst_work_path = translated_path(src_menu.path, lang)
      next if dst_work_path.blank?

      dst_menu = ::Menu.find_by(page_id: dst.id, path: dst_work_path)
      copy_menu_gold(src_menu, dst_menu, is_dry_run)
    end
  end
end
