puts Verse.column_names.join(' ')
q=Page.find(4538); h=q.body_rendered.to_s
bad=[]
col = Verse.column_names.include?('book_code') ? 'book_code' : 'book'
h.scan(%r{/ru/ru/([\w-]+)/(\d+)#L(\d+)}).uniq.each do |b,c,v|
  code = BOOKS[b.to_sym] rescue nil
  r = Verse.where(lang:'ru', chapter:c.to_i, line:v.to_i).where(book: (BOOKS.dig(b.to_sym,:id) rescue nil)).exists? rescue :err
  bad << [b,c,v,r] unless r==true
end
puts "проблемы: #{bad.first(10).inspect} из #{h.scan(%r{/ru/ru/([\w-]+)/(\d+)#L(\d+)}).uniq.size}"
