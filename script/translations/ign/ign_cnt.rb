g=Page.where("path LIKE ?", "ИгнАн%").pluck(:group_lang_id)
g.each{|gid| r=Page.where(group_lang_id: gid, lang: %w[grc ru en]).order(:lang).map{|p| "#{p.lang}:#{p.verses.size}ch/#{p.verses.sum{|c| c['lines'].size}}L/#{p.body.gsub(/<[^>]+>/,'').size}c"}; puts r.join("  ")}
p=Page.find(142); p.verses[1]['lines'].each{|l| puts "G| "+l}; Page.find(137).verses[1]['lines'].each{|l| puts "R| "+l.gsub(/<[^>]+>/,'')}
