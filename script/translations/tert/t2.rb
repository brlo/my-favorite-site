Menu.where("title LIKE ?",'%тыдлив%').each{|m| puts [m.id,m.page_id,m.title,m.path].inspect}
Page.where(lang:'ru').where("body LIKE '%wvx9_%'").each{|q| puts q.path, q.body.scan(/.{60}wvx9_.{0,10}/).first(2), q.body.scan(/[^<>]{0,50}О стыдливости[^<>]{0,50}/).first(3).inspect}
