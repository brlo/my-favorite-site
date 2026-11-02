require 'sqlite3'
{'tmp/bibles/HIND.SQLite3'=>'hi','tmp/bibles/CTB.SQLite3'=>'ko','tmp/bibles/SB.SQLite3'=>'zh'}.each do |f,l|
  db=SQLite3::Database.new(f, readonly: true); rows=db.execute('select book_number,chapter,verse,text from verses')
  cleaned=rows.map{|b,c,v,t| [b,c,v,MybibleImporter.clean(t)]}
  bad=cleaned.select{|*,t| t =~ /[<>\[\]]|[ㄱ-ㅎ]\)|\([ㄱ-ㅎ]\./}
  unk=rows.reject{|b,*| MybibleImporter::BOOK_BY_ID[b.to_i]}
  puts "#{f}: #{rows.size} rows, blank=#{cleaned.count{|*,t| t.empty?}}, unknown_book=#{unk.size} #{unk.first(2).map{|r| r.map{|x| x.to_s[0,30]}}.inspect}, leftover=#{bad.size}"
  bad.first(6).each{|r| puts "   #{r[0]} #{r[1]}:#{r[2]} #{r[3][0,160]}"}
end
