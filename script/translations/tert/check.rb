q=Page.find(4538)
puts q.title, q.title_sub, q.body.size, q.body_rendered.to_s.size
h=q.body_rendered.to_s
links=h.scan(/<a [^>]*href="([^"]+)"[^>]*>([^<]*)<\/a>/)
puts "links #{links.size}"
puts links.map{|u,t| "#{t} => #{u}"}.first(6)
vis=Nokogiri::HTML(h).text
refs=vis.scan(/\((?:[1-3] )?[А-Я][а-я]+\. ?\d+:[^)]*\)/).uniq
puts "в скобках #{refs.size}"
unl=q.body.scan(/\(((?:[1-3] )?[А-Я][а-я]+\.? ?\d+:[^)]*)\)/).flatten.uniq.reject{|r| h.include?(r.split(';').first.strip)}
puts "непривязанные: #{unl.inspect}"
cites=links.map{|u,_|u}
missing=[]
q.body.scan(/((?:[1-3] )?[А-Я][а-я]+\.) ?(\d+):(\d+)/).uniq.each{|b,c,v| code=BibleCitationExtractor.book_code_for(b); (missing<<"#{b} #{c}:#{v} nobook"; next) unless code; ok=Verse.where(lang:'ru',book_code:code,chapter:c.to_i,line:v.to_i).exists? rescue (missing<<"err"; next); missing<<"#{b} #{c}:#{v}" unless ok}
puts "нет стиха: #{missing.uniq.inspect}"
