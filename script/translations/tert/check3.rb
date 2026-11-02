puts Verse.where(lang:'ru').first.attributes.slice('tr_code','book','book_id','address').inspect
q=Page.find(4538); h=q.body_rendered.to_s
all=h.scan(%r{/ru/ru/([\w-]+)/(\d+)#L(\d+)}).uniq
bad=all.reject{|b,c,v| Verse.where(tr_code:'ru', book:b, chapter:c.to_i, line:v.to_i).exists? || Verse.where(tr_code:'ru', address:"#{b} #{c}:#{v}").exists?}
puts "проверено #{all.size}, нет: #{bad.inspect}"
