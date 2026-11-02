%w[wvx9_О_стыдливости_De_Pudicitia 4xbT_О_единоженстве 2dNZ_О_покрывале_девственниц NqoW_О_посте iRVv_О_бегстве_во_время_гонений].each do |pa|
  p1 = Page.find_by(path_low: pa.downcase) || Page.find_by(path: pa)
  puts "=== #{pa}: #{p1&.id}"
  next unless p1
  puts({title: p1.title, sub: p1.title_sub, desc: p1.meta_desc, lang: p1.lang, g: p1.group_lang_id, em: p1.edit_mode, body: p1.body.to_s.size, verses: p1.verses.to_s.size, refs: p1.references.to_s.size, pub: p1.attributes['is_published'], del: p1.is_deleted, cover: p1.cover, redirect: p1.redirect_from}.inspect)
  puts "BODY_START: " + p1.body.to_s[0,500]
  puts "VERSES_START: " + p1.verses.to_s[0,500]
  puts "REFS_START: " + p1.references.to_s[0,300]
  Page.where(group_lang_id: p1.group_lang_id).each { |q| puts [q.id,q.lang,q.path,q.title,q.body.to_s.size,q.verses.to_s.size,q.references.to_s.size].inspect } if p1.group_lang_id
  File.write("tmp/tert/old_#{pa[0,4]}.json", p1.attributes.slice('title','title_sub','meta_desc','path','body','verses','references').to_json)
end
