g = Page.find_by!(lang: 'ru', path: 'Евхаристия').group_lang_id
%w[ru en ja].each do |l|
  pg = Page.find_by!(lang: l, group_lang_id: g)
  puts "@@@ #{l} #{pg.id} #{pg.path} #{pg.updated_at} refs=#{pg.references.to_s.size}"
  puts pg.body
end
