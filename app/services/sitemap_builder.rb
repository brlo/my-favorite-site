# Собирает карту сайта public/sitemaps/sitemap.xml.gz (nginx отдаёт её как /sitemap.xml.gz)
# из опубликованных статей, по их каноническим адресам.
#
#   SitemapBuilder.call -> число адресов
class SitemapBuilder
  DIR = 'sitemaps/'.freeze

  def self.call
    require 'sitemap_generator'
    public_path = Rails.root.join('public').to_s + '/'

    # Карта карт для Google: архивированную версию напрямую он парсить не хочет
    ::File.write(::File.join(public_path, DIR, 'sitemap.xml'),
      '<?xml version="1.0" encoding="UTF-8"?>' \
      '<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' \
      "<sitemap><loc>#{::Page::SITE_URL}/sitemap.xml.gz</loc></sitemap>" \
      '</sitemapindex>')

    count = 0
    ::SitemapGenerator::Sitemap.default_host = ::Page::SITE_URL
    ::SitemapGenerator::Sitemap.public_path = public_path
    ::SitemapGenerator::Sitemap.sitemaps_path = DIR
    ::SitemapGenerator::Sitemap.verbose = false
    ::SitemapGenerator::Sitemap.create do
      ::Page.published.where(is_deleted: [nil, false]).select(:id, :lang, :path, :updated_at).find_each do |p|
        add ::Page.path_for(p.lang, p.path), lastmod: p.updated_at
        count += 1
      end
    end
    count
  end
end
