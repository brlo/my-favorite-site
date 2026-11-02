p=Page.find(138); File.write('tmp/ign/ru138_body.html', p.body); File.write('tmp/ign/ru138_refs.html', p.references.to_s)
puts p.title, p.title_sub.inspect, p.meta_desc.inspect, p.body.size, p.references.to_s.size
j=Page.find(951); puts j.title, j.title_sub.inspect, j.meta_desc.inspect, j.references.to_s[0,300]
