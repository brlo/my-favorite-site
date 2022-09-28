namespace :g do
  # cd /app/backend && HOME=/app/backend RACK_ENV=production bundle exec rake g:sitemap FOR_PLACE_SIZE=big
  desc "Generate sitemap"
  task :sitemap => :environment do
    require 'sitemap_generator'

    site_url = 'https://bibleox.com'
    # будет в public
    path = '/sitemaps/'
    changefreq = 'monthly'

    puts "Start generating sitemap..."

    SitemapGenerator::Sitemap.sitemaps_path = path
    SitemapGenerator::Sitemap.default_host = site_url
    SitemapGenerator::Sitemap.create do
      # Добавляется автоматически:
      # add "/", :priority => 1.0
      # add '/q', :changefreq => 'weekly', :priority => 0.8
      add '/ru/about/', :changefreq => changefreq, :priority => 0.7
      add '/ru/search/', :changefreq => changefreq, :priority => 0.7
      add '/en/about/', :changefreq => changefreq, :priority => 0.7
      add '/en/search/', :changefreq => changefreq, :priority => 0.7

      %w(ru en il gr cs).each do |locale|
        ::BOOKS.each do |book_code, params|
          (1..params[:chapters]).each do |chapter|
            add "/#{locale}/#{book_code}/#{chapter}/", :changefreq => changefreq, :priority => 0.9
          end
        end
      end
    end

    puts "Sitemap builded! ✅"
  end
end
