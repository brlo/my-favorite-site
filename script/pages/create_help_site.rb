# Страницы «Помощь сайту» (пункт меню «⋯» в шапке): help_<язык> для всех языков интерфейса.
# Текст берётся из локалей (about_funding, about_prayer, about_donate_html), заголовок — menu.help_site.
# bin/rails runner script/pages/create_help_site.rb  (DRY_RUN=1 — только показать). Существующие страницы не трогает.
group = "help_site"
::ALL_LOCALES.each_key do |lang|
  path = "help_#{lang}"
  if Page.exists?(path_low: path.downcase)
    puts "skip #{path}: exists"
    next
  end
  I18n.with_locale(lang) do
    title = I18n.t('menu.help_site')
    body = [
      "<p>#{I18n.t('about_funding')}</p>",
      "<p>#{I18n.t('about_prayer')}</p>",
      "<p>#{I18n.t('about_donate_html', bank: '<span style="color: #0D8523">СБЕР</span>', card: '<strong>2202 2082 9863 8306</strong>')}</p>",
    ].join("\n")
    if ENV['DRY_RUN']
      puts "[DRY RUN] #{lang}:#{path} (#{title})"
    else
      page = Page.create!(lang: lang, path: path, title: title, meta_desc: I18n.t('about_prayer'), body: body,
                          group_lang_id: group, is_published: true, page_type: 1)
      puts "created #{page.id} #{lang}:#{path} (#{title})"
    end
  end
end
