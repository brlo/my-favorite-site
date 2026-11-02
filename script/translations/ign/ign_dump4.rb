p=Page.find(951); puts p.body.scan(/<a [^>]*>/).first(10); puts p.title_sub.inspect, p.meta_desc.inspect, p.references.to_s[0,500]
r=Page.find(138); puts "RU links:"; puts r.body.scan(/<a [^>]*>[^<]*<\/a>/).first(15)
puts r.body[r.body.index("единственный врач")-200, 900] rescue puts "nf"
