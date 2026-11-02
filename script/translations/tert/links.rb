paths=%w[wvx9_ 4xbT_ 2dNZ_ NqoW_ iRVv_]
paths.each{|x| Page.where("body LIKE ? OR body_menu::text LIKE ? OR \"references\" LIKE ?", "%#{x}%","%#{x}%","%#{x}%").each{|q| s=(q.body.to_s+q.references.to_s); puts [x,q.id,q.lang,q.path,s.scan(/#{x}[^"]{0,70}/).first(3)].inspect}}
puts Page.where("body LIKE ?", '%PL2.%').group(:lang).count.inspect
ru=Page.where(lang:'ru').where("body LIKE '%<sup%' AND \"references\" LIKE '%<ol>%'").first
puts ru&.path, ru&.body.to_s[0,400], ru&.references.to_s[0,500]
puts Menu.where(page_id: Page.where(id:[4538,4518,4546,4547,4539]).select(:id)).count
