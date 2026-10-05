# Выгрузка данных для оффлайн-приложения (Android).
#
# Приложение хранит у себя:
#   - переводы Библии целиком (пакет на перевод, скачивается при первом открытии перевода онлайн);
#   - «скелет» материалов языка: заголовки, иерархию и меню всех страниц (синхронизируется дельтой);
#   - тексты страниц — только тех, что открывали онлайн или скачали разделом.
#
# Поисковый индекс строится на устройстве, поэтому сюда отдаём сырые данные.
module Offline
  module Export
    module_function

    # Переводы, доступные оффлайн. gr-ru — это подстрочник (служебные данные), его не отдаём.
    EXCLUDED_TR_CODES = %w[gr-ru].freeze
    VERSE_TAGS = %w[j e i br ruby rb rt].freeze
    PACKS_DIR = Rails.root.join('public', 's', 'offline')
    MAX_PAGES_PER_REQUEST = 100

    def tr_codes
      ::Rails.cache.fetch('offline:tr_codes', expires_in: 1.hour) do
        ::Verse.distinct.pluck(:tr_code).sort - EXCLUDED_TR_CODES
      end
    end

    # Версия перевода меняется при любой правке стихов
    def bible_versions
      ::Rails.cache.fetch('offline:bible_versions', expires_in: 10.minutes) do
        ::Verse.where(tr_code: tr_codes).group(:tr_code)
          .pluck(:tr_code, ::Arel.sql('MAX(updated_at)'), ::Arel.sql('COUNT(*)'))
          .to_h { |tr, max_at, cnt| [tr, "#{max_at.to_i}-#{cnt}"] }
      end
    end

    # Главы, для которых есть аудио: { 'gen' => [1, 2, ...] }
    def bible_audio(tr_code)
      ::Rails.cache.fetch("offline:bible_audio:#{tr_code}", expires_in: 1.hour) do
        dir = Rails.root.join('public', 's', 'audio', 'bib', tr_code)
        res = ::Hash.new { |h, k| h[k] = [] }
        ::Dir.glob(dir.join('*', '*.mp3')).each do |f|
          book = ::File.basename(::File.dirname(f))
          chapter = ::File.basename(f, '.mp3').delete_prefix(book).to_i
          res[book] << chapter if chapter > 0
        end
        res.transform_values(&:sort)
      end
    end

    def manifest(locale:)
      versions = bible_versions
      {
        server_time: ::Time.now.to_i,
        res_base: res_base,
        books: ::BOOKS.map do |code, b|
          {
            code: code,
            chapters: b[:chapters],
            zavet: b[:zavet],
            name: ::I18n.t("books.mid.#{code}", locale: locale, default: b[:name]),
            short: ::I18n.t("books.short.#{code}", locale: locale, default: code),
          }
        end,
        bible: tr_codes.map do |tr|
          {
            tr_code: tr,
            title: ::BIB_LANGS[tr] || tr,
            desc: ::I18n.t("breadcrumbs.bib_langs.vz.#{tr}", locale: locale, default: ''),
            locale: ::BIB_LANG_TO_LOCALE[tr],
            version: versions[tr],
            audio: bible_audio(tr),
          }
        end,
        page_langs: ::Page.published.where(is_deleted: [false, nil]).group(:lang).count,
      }
    end

    # Путь к gz-файлу с переводом. Собирается при первом запросе версии.
    def bible_pack_path(tr_code)
      version = bible_versions[tr_code] or return nil
      path = PACKS_DIR.join("bible-#{tr_code}-#{version}.json.gz")
      build_bible_pack(tr_code, version, path) unless ::File.exist?(path)
      path
    end

    def build_bible_pack(tr_code, version, path)
      ::FileUtils.mkdir_p(PACKS_DIR)
      sanitizer = ::Rails::Html::SafeListSanitizer.new
      verses = ::Verse.where(tr_code: tr_code).order(:book_id, :chapter, :line)
        .pluck(:book, :chapter, :line, :text)
        .map { |book, ch, line, text| [book, ch, line, sanitizer.sanitize(text, tags: VERSE_TAGS)] }

      data = { tr_code: tr_code, version: version, verses: verses }

      # пишем во временный файл и переименовываем, чтобы параллельный запрос не отдал недописанный файл
      tmp = "#{path}.#{::SecureRandom.hex(6)}.tmp"
      ::Zlib::GzipWriter.open(tmp, ::Zlib::BEST_COMPRESSION) { |gz| gz.write(::JSON.generate(data)) }
      ::File.rename(tmp, path)

      # старые версии этого перевода больше не нужны
      ::Dir.glob(PACKS_DIR.join("bible-#{tr_code}-*.json.gz")).each do |f|
        ::File.delete(f) unless f == path.to_s
      end
    end

    def lang_pages(lang)
      ::Page.where(lang: lang, is_published: true, is_deleted: [false, nil])
    end

    # Скелет материалов языка: всё, кроме текстов страниц.
    # since — unix-время прошлой синхронизации (0 — всё целиком).
    # Удалённые записи клиент вычисляет по полным спискам page_ids/menu_ids.
    def skeleton(lang:, since: 0)
      started_at = ::Time.now
      since_t = ::Time.at(since.to_i)
      pages = lang_pages(lang)
      menus = ::Menu.where(page_id: pages.select(:id))

      changed_pages = pages.where('updated_at > ?', since_t)
        .select(:id, :path, :title, :title_sub, :parent_id, :page_type, :is_show_parent, :is_search,
                :is_menu_icons, :is_bibleox, :links, :cover, :audio, :updated_at, :lang, :h_id, :created_at)
        .select('octet_length(body_rendered) AS body_size')
        .to_a

      {
        lang: lang,
        # небольшой нахлёст, чтобы не потерять записи, сохранённые во время выгрузки
        next_since: (started_at - 60).to_i,
        full: since.to_i <= 0,
        pages: changed_pages.map { |p| page_meta(p) },
        menus: menus.where('updated_at > ?', since_t)
          .pluck(:id, :page_id, :parent_id, :title, :path, :priority, :is_gold, :is_empty),
        page_ids: pages.ids,
        menu_ids: menus.ids,
      }
    end

    def page_meta(p)
      {
        id: p.id,
        path: p.path,
        title: p.title,
        title_sub: p.title_sub.presence,
        parent_id: p.parent_id,
        page_type: p.page_type,
        is_show_parent: p.is_show_parent,
        is_search: p.is_search,
        is_bibleox: p.is_bibleox,
        links: p.links.presence,
        cover: p.cover? ? p.cover.large.url : nil,
        icon: (p.cover? && p.is_menu_icons) ? p.cover.micro.url : nil,
        audio: page_audio_url(p),
        body_size: p.attributes['body_size'].to_i,
        updated_at: p.updated_at.to_i,
      }
    end

    def page_audio_url(p)
      return nil if p.audio.blank?
      file = "/s/audio/pages/#{p.lang}/#{p.audio}.mp3"
      ::File.exist?(Rails.root.join("public#{file}")) ? file : nil
    end

    # Полные тексты страниц
    def pages(lang:, ids:)
      ids = ids.map(&:to_i).uniq.first(MAX_PAGES_PER_REQUEST)
      lang_pages(lang).where(id: ids).map do |p|
        {
          id: p.id,
          updated_at: p.updated_at.to_i,
          body: p.body_rendered.presence || p.body.to_s,
          references: p.references.present? ? (p.references_rendered.presence || p.references) : nil,
          body_menu: p.body_menu.presence,
          verses: p.is_page_verses? ? p.verses.presence : nil,
        }
      end
    end

    def res_base
      host = ::Rails.application.config.asset_host
      host.present? ? "https://#{host.delete_prefix('https://').delete_prefix('http://')}" : nil
    end
  end
end
