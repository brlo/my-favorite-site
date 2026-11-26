# frozen_string_literal: true

# Убирает внешние ссылки на Азбуку с авторских страниц de/fr.
# Если цитата есть на нашем сайте — ставит внутреннюю ссылку; если нет —
# оставляет текст без активной ссылки (как и просил пользователь).
#
#   bin/rails runner script/translations/de/retarget_author_links.rb [APPLY=1]

apply = ARGV.include?('APPLY=1')

DE_WORKS = {
  'Irenaeus_von_Lyon' => {
    'apostolic_preaching' => 'Irenaeus_Demonstratio',
  },
  'Tertullian' => {
    'apologetik' => 'Tertullian_Apologeticum',
    'o-ventse-voina' => 'Tertullian_De_corona',
    'o_kreshenii' => 'Tertullian_De_baptismo',
    'o_molitve' => 'Tertullian_De_oratione',
    'ob_idolopokl' => 'Tertullian_De_idololatria',
    'poslanie_k_zhene' => 'Tertullian_Ad_uxorem',
    'protiv-prakseja' => 'Tertullian_Adversus_Praxean',
  },
}.freeze

FR_TO_DE = {
  'IrLn_Irénée_de_Lyon_IIe_siècle' => 'Irenaeus_von_Lyon',
  'Trll_Tertullien_IIe_IIIe_siècle' => 'Tertullian',
  'CpCr_Cyprien_de_Carthage_IIIe_siècle' => 'Cyprian_von_Karthago',
}.freeze

def internal_href(lang, page_path, href)
  de_author = lang == 'fr' ? FR_TO_DE[page_path] : page_path
  return nil if de_author.nil?

  author = DE_WORKS[de_author]
  return nil if author.nil?

  if de_author == 'Irenaeus_von_Lyon' && (m = href.match(%r{/protiv-eresej/(\d+)(?:_(\d+))?}))
    book = m[1]
    chapter = m[2]
    target = "Irenaeus_Gegen_die_Haeresien_#{book}"
  else
    slug = href[%r{/otechnik/[^/]+/([^/#?]+)}, 1]
    target = slug && author[slug]
  end
  return nil unless target

  if lang == 'de'
    "/de/de/w/#{target}"
  else
    de_page = ::Page.find_by(lang: 'de', path: target)
    fr_page = de_page && ::Page.find_by(lang: 'fr', group_lang_id: de_page.group_lang_id)
    fr_page ? "/fr/fr/w/#{fr_page.path}" : nil
  end
end

changed = 0
report = []
::Page.where(lang: %w[de fr], page_type: 4).where("body LIKE '%azbyka.ru%'").find_each do |page|
  fragment = Nokogiri::HTML.fragment(page.body)
  links = fragment.css('a[href*="azbyka.ru"]')
  links.each do |a|
    href = a['href'].to_s
    replacement = internal_href(page.lang, page.path, href)
    if replacement
      a['href'] = replacement
      report << [page.path, '->', replacement]
    else
      a.replace(a.children)
      report << [page.path, 'снята ссылка', href]
    end
    changed += 1
  end
  html = fragment.to_html.gsub(%r{https?://azbyka\.ru[^\s<]*}, '').gsub(/:\s*<\/p>/, '.</p>')
  page.update!(body: html) if apply
end

puts "#{apply ? '' : 'DRY RUN '}ссылок обработано: #{changed}"
report.first(80).each { |row| puts row.join(' ') }
