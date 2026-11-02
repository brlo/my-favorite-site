# Проверка внутренних якорей #HH-... в японских статьях jp_q
pages = Page.where(lang: 'ja')
pages.find_each do |p|
  html = [p.body, p.respond_to?(:references) ? p.references : nil].compact.join
  doc = Nokogiri::HTML(html)
  ids = Hash.new(0); have = []
  doc.css('h2,h3,h4').each do |el|
    t = el.text.gsub(/[^[[:alnum:]]\s\-]/, '').gsub(' ', '-')
    i = (ids[t] += 1); have << "HH#{i == 1 ? nil : i}-#{t}"
  end
  html.scan(/href="#(HH[^"]*)"/).flatten.uniq.each do |a|
    a2 = CGI.unescape(a)
    puts "#{p.path}: нет якоря #{a2}" unless have.include?(a2)
  end
end
puts 'ok'
