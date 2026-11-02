# То же, что tmp/ja_marks.rb, но для уже перелинкованных японских страниц в базе:
# у ссылок на японские статьи пометку «（ロシア語）» убираем, у оставшихся ссылок на русские — ставим.
#   bin/rails runner tmp/ja_marks_db.rb [DRY]
is_dry = ARGV.include?('DRY')
mark = '（ロシア語）'
m_re = Regexp.escape(mark)
list = Page.find_by!(lang: 'ja', path_low: 'jp_q')
Page.where(lang: 'ja', parent_id: list.id).find_each do |pg|
  stats = Hash.new(0)
  changes = %w[body references].to_h do |field|
    html = pg[field].to_s
    html = html.gsub(%r{(<a href="https://bibleox\.com/ja/ja/w/[^"]+">)(.*?)</a>(#{m_re})?}) do
      whole, open, label, after = $&, $1, $2, $3
      clean = label.sub(/#{m_re}\z/, '')
      next whole if clean == label && after.nil?

      stats[:removed] += 1
      "#{open}#{clean}</a>"
    end
    html = html.gsub(%r{<a href="https?://bibleox\.com/ru/(?:ru/w|q)/[^"]+">(.*?)</a>(#{m_re})?(?=([^<]{0,8}))}) do
      label, after, tail = $1, $2, $3
      next $& if after || label.include?('ロシア語') || tail.include?('ロシア語')

      stats[:added] += 1
      $& + mark
    end
    [field, html]
  end.select { |field, html| html != pg[field].to_s }
  next if changes.empty?

  puts "#{pg.path}: #{stats.to_h}"
  pg.update!(changes) unless is_dry
end
