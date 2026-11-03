# Страницы «Помощь сайту» (пункт меню «⋯» в шапке): help_<язык> для всех языков интерфейса.
# Текст берётся из локалей (about_funding, about_prayer, about_donate_html), заголовок — menu.help_site.
# bin/rails runner script/pages/create_help_site.rb  (DRY_RUN=1 — только показать). Существующие страницы не трогает,
# если не задан UPDATE=1: тогда у них пересобирается body (ручные правки затираются, сначала DRY_RUN=1 и бэкап).
group = "help_site"
::ALL_LOCALES.each_key do |lang|
  path = "help_#{lang}"
  existing = Page.find_by(path_low: path.downcase)
  if existing && !ENV['UPDATE']
    puts "skip #{path}: exists"
    next
  end
  I18n.with_locale(lang) do
    title = I18n.t('menu.help_site')
    body = [
      "<p>#{I18n.t('about_funding')}</p>",
      "<p>#{I18n.t('about_prayer')}</p>",
      "<p>#{I18n.t('about_donate_html', bank: %(<span style="color: #0D8523">#{lang == 'ru' ? 'СБЕР' : 'SBER'}</span>), card: '<strong>2202 2082 9863 8306</strong>')}</p>",
      "<p>SBER · RODION VLASOV</p>",
    ].join("\n")
    if ENV['DRY_RUN']
      puts "[DRY RUN] #{lang}:#{path} (#{title})#{existing ? ' update' : ''}"
    elsif existing
      existing.update!(body: body)
      puts "updated #{existing.id} #{lang}:#{path}"
    else
      page = Page.create!(lang: lang, path: path, title: title, meta_desc: I18n.t('about_prayer'), body: body,
                          group_lang_id: group, is_published: true, page_type: 1)
      puts "created #{page.id} #{lang}:#{path} (#{title})"
    end
  end
end
