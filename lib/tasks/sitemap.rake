namespace :g do
  # Ежедневно собирается задачей SitemapJob (config/recurring.yml); руками: bin/rails g:sitemap
  desc "Generate sitemap"
  task :sitemap => :environment do
    puts "Start generating sitemap..."
    count = ::SitemapBuilder.call
    puts "Sitemap builded: #{count} urls ✅"
  end

  # Отправить поисковикам (IndexNow) адреса опубликованных статей раздела: bin/rails g:index_now LIST=en-q LANG=en
  desc "Send IndexNow notification for published pages of a list"
  task :index_now => :environment do
    list = ::Page.find_by!(lang: ENV.fetch('LANG'), path: ENV.fetch('LIST'))
    urls = ::Page.published.where(parent_id: list.id, is_deleted: [nil, false]).map(&:canonical_url)
    puts "urls: #{urls.size}"
    puts ::IndexNowService.notify_batch(urls).inspect
  end
end
