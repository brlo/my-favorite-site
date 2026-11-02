# Пометки «（ロシア語）» у ссылок на русские статьи в db/translations/ja/*.yml:
# если у статьи есть японский перевод (релинкер её заменит) — пометку убираем,
# если нет — ставим после ссылки.
#   bin/rails runner tmp/ja_marks.rb [DRY]
is_dry = ARGV.include?('DRY')
mark = '（ロシア語）'
href_re = %r{<a href="https?://bibleox\.com/ru/(?:ru/w|q)/([^"#?/]+)/?(?:#[^"]*)?">(.*?)</a>(#{Regexp.escape(mark)})?(?=([^<]{0,8}))}
cache = {}
translated = lambda do |path|
  cache.fetch(path) do
    src = Page.find_by(lang: 'ru', path_low: path.downcase)
    cache[path] = src.present? && Page.exists?(lang: 'ja', group_lang_id: src.group_lang_id)
  end
end

Dir['db/translations/ja/*.yml'].sort.each do |file|
  text = File.read(file)
  stats = Hash.new(0)
  fixed = text.gsub(href_re) do |m|
    path, label, after, tail = CGI.unescape($1), $2, $3, $4
    if translated.(path)
      clean = label.sub(/#{Regexp.escape(mark)}\z/, '')
      next m if clean == label && after.nil?

      stats[:removed] += 1
      m.sub(label, clean).delete_suffix(after.to_s)
    else
      next m if after || label.include?("ロシア語") || tail.include?("ロシア語")

      stats[:added] += 1
      m + mark
    end
  end
  next if stats.empty?

  puts "#{file}: #{stats.to_h}"
  File.write(file, fixed) unless is_dry
end
