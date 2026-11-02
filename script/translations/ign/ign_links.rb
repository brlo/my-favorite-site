require 'cgi'
pages = Page.where(lang: 'ja').where("path LIKE 'Ig1%'").to_a
chapters = pages.to_h { |p| [p.path, p.body.scan(/<h2[^>]*>(\d+)<\/h2>/).flatten.to_set] }
bad = []; n = 0
pages.each do |p|
  html = p.body.to_s + p.references.to_s
  html.scan(/href="([^"]+)"/).flatten.each do |href|
    n += 1
    if href =~ %r{bibleox\.com/ja/jp-ni/([^/]+)/(\d+)/#L([\d\-,]+)}
      b, c, vs = $1, $2.to_i, $3
      lines = vs.split(',').flat_map { |r| a, z = r.split('-').map(&:to_i); (a..(z || a)).to_a }
      have = Verse.where(tr_code: 'jp-ni', book: b, chapter: c, line: lines).count
      bad << "#{p.path}: #{href} (#{have}/#{lines.size})" if have != lines.size
    elsif href =~ %r{bibleox\.com/ja/ja/w/([^#]+)#HH-(\d+)}
      path, ch = CGI.unescape($1), $2
      bad << "#{p.path}: #{href} (no page/chapter)" unless chapters[path]&.include?(ch)
    elsif href =~ /\A#HH-(\d+)\z/
      bad << "#{p.path}: #{href} (no chapter)" unless chapters[p.path].include?($1)
    elsif href =~ %r{bibleox\.com/ja/grc/w/}
    else
      bad << "#{p.path}: unknown #{href}"
    end
  end
end
puts "links: #{n}, bad: #{bad.size}"; puts bad
Menu.find(1201).update!(priority: 5)
