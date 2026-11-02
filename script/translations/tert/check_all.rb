{4538=>'fuga',4547=>'virg',4539=>'jej',4546=>'mono',4518=>'pud'}.each do |id,n|
  q=Page.find(id); h=q.body_rendered.to_s
  all=h.scan(%r{/ru/ru/([\w-]+)/(\d+)#L(\d+)}).uniq
  bad=all.reject{|b,c,v| Verse.where(tr_code:'ru',address:"#{b}:#{c}:#{v}").exists?}
  plain=Nokogiri::HTML(h).css('p').map(&:text).join(' ')
  unl=q.body.scan(/\(([^()]*?\d+:\d+[^()]*)\)/).flatten.reject{|r| h.scan(r.split(/[;,]/).first.strip).size>0 && true}
  linked=Nokogiri::HTML(h).css('a').map(&:text)
  unlinked=q.body.scan(/(?:[1-3] )?[А-Я][а-я]+\. \d+:\d+/).uniq.reject{|r| linked.any?{|t| t.start_with?(r)||t.include?(r)}}
  puts "#{n}: #{q.title} body=#{q.body.size} стихов=#{all.size} нет=#{bad.inspect} непривязанные=#{unlinked.first(15).inspect} PL=#{q.body.scan('PL2').size} leftover={{=#{q.body.include?('{{')}"
end
