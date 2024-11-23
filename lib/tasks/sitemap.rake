namespace :g do
  # RACK_ENV=production bundle exec rake g:sitemap
  desc "Generate sitemap"
  task :sitemap => :environment do
    require 'sitemap_generator'

    site_url = 'https://bibleox.com'
    # будет в public
    path = 'sitemaps/'
    changefreq = 'monthly'

    puts "Start generating sitemap..."

    # Записываем карту карт сайта для Google. Он упорно не хочет парсить архивированную версию напрямую.
    ::File.open('public/sitemaps/sitemap.xml', 'w') do |file|
      file.write('<?xml version="1.0" encoding="UTF-8"?>')
      file.write('<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
      file.write('<sitemap>')
      file.write('<loc>https://bibleox.com/sitemap.xml.gz</loc>')
      file.write('</sitemap>')
      file.write('</sitemapindex>')
    end

    # А теперь и сама карта сайта
    SitemapGenerator::Sitemap.sitemaps_path = path
    SitemapGenerator::Sitemap.default_host = site_url
    SitemapGenerator::Sitemap.create do
      # Добавляется автоматически:
      # add "/", :priority => 1.0
      # add '/q', :changefreq => 'weekly', :priority => 0.8
      locales = ::I18n.available_locales.map(&:to_s)

      ::Page.each do |p|
        # ПРОПУСКАЕМ, если:
        # - не опубликована?
        next if p.is_pub == false
        # - удалена?
        next if p.is_del == true

        add "/#{p.lang}/#{p.lang}/w/#{p.path}/", :changefreq => changefreq, :priority => 0.9
      end

      locales.each do |lang|
        add "/#{lang}/about/", :changefreq => changefreq, :priority => 0.7
      end

      ::ApplicationHelper::LANG_CONTENT_TO_LANG_UI.each do |lang_content, lang_ui|
        # некоторые языки не индексируем
        next if ::ApplicationHelper::NOT_INDEXED_LANGS.include?(lang_content)

        ::BOOKS.each do |book_code, params|
          (1..params[:chapters]).each do |chapter|
            add "/#{lang_ui}/#{lang_content}/#{book_code}/#{chapter}/", :changefreq => changefreq, :priority => 0.9
          end
        end
      end
    end

    puts "Sitemap builded! ✅"
  end
end
