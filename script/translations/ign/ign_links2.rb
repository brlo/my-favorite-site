require 'cgi'
def anchors(page) = page.body.to_s.scan(/<h[234][^>]*>(.*?)<\/h[234]>/m).flatten.map { |t| 'HH-' + Nokogiri::HTML(t).text.gsub(/[^[[:alnum:]]\s\-]/, '').gsub(' ', '-') }.to_set
p = Page.find(951); bad = []; n = 0
(p.body + p.references.to_s).scan(/href="([^"]+)"/).flatten.each do |href|
  n += 1
  if href =~ %r{bibleox\.com/ja/jp-ni/([^/]+)/(\d+)/#L([\d\-,]+)}
    lines = $3.split(',').flat_map { |r| a, z = r.split('-').map(&:to_i); (a..(z || a)).to_a }
    bad << href if Verse.where(tr_code: 'jp-ni', book: $1, chapter: $2.to_i, line: lines).count != lines.size
  elsif href =~ %r{bibleox\.com/(?:ja|ru)/(ja|en|grc|ru)/w/([^#]+)(?:#(.+))?}
    lang, path, anchor = $1, CGI.unescape($2), $3 && CGI.unescape($3)
    pg = Page.find_by(lang: lang, path: path)
    bad << "#{href} (no page)" and next unless pg
    bad << "#{href} (no anchor)" if anchor && !anchors(pg).include?(anchor)
  elsif href !~ /azbyka\.ru/
    bad << "unknown #{href}"
  end
end
puts "links: #{n}, bad: #{bad.size}"; puts bad
