puts Verse.distinct.pluck(:tr_code).sort.join(" ")
p=Page.find(387); p.verses.each_with_index{|c,i| puts "#{i}: #{c['title']} (#{c['lines'].size})"}
