# Проверка ссылок в переводах Игнатия: стихи Библии, страницы и якоря глав.
# bin/rails runner tmp/ign_check.rb LANG TR PATH_PREFIX [ALLOW_MISSING=1]
#   LANG=zh-Hans TR=cn-sb PATH_PREFIX=Ig4  -> все страницы lang с path LIKE 'Ig4%' и страница автора
require 'cgi'
lang, tr, prefix = ARGV
allow_missing = ENV['ALLOW_MISSING'].present?

def anchors(page)
  page.body.to_s.scan(/<h[234][^>]*>(.*?)<\/h[234]>/m).flatten.map { |t| 'HH-' + Nokogiri::HTML(t).text.gsub(/[^[[:alnum:]]\s\-]/, '').gsub(' ', '-') }.to_set
end

pages = Page.where(lang: lang).where('path LIKE ?', "#{prefix}%").to_a
bad = []; n = 0; missing = Hash.new(0)
pages.each do |p|
  own = anchors(p)
  (p.body.to_s + p.references.to_s).scan(/href="([^"]+)"/).flatten.each do |href|
    n += 1
    if href =~ %r{bibleox\.com/[^/]+/#{Regexp.escape(tr)}/([^/]+)/(\d+)/#L([\d\-,]+)}
      book, ch = $1, $2.to_i
      lines = $3.split(',').flat_map { |r| a, z = r.split('-').map(&:to_i); (a..(z || a)).to_a }
      have = Verse.where(tr_code: tr, book: book, chapter: ch, line: lines).count
      bad << "#{p.path}: #{href} (#{have}/#{lines.size})" if have != lines.size
    elsif href =~ %r{bibleox\.com/[^/]+/([^/]+)/w/([^#]+)(?:#(.+))?}
      plang, path, anchor = $1, CGI.unescape($2), $3 && CGI.unescape($3)
      pg = Page.find_by(lang: plang, path: path)
      if pg.nil?
        allow_missing ? missing[path] += 1 : bad << "#{p.path}: #{href} (no page)"
      elsif anchor && !anchors(pg).include?(anchor)
        bad << "#{p.path}: #{href} (no anchor)"
      end
    elsif href =~ /\A#(HH-.+)\z/
      bad << "#{p.path}: #{href} (no own anchor)" unless own.include?(CGI.unescape($1))
    elsif href !~ /azbyka\.ru/
      bad << "#{p.path}: unknown #{href}"
    end
  end
end
puts "pages: #{pages.size}, links: #{n}, bad: #{bad.size}"
puts "not yet imported: #{missing.keys.join(', ')}" if missing.any?
puts bad
