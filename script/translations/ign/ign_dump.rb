%w[142 137 143 1209].each{|id| p=Page.find(id); puts "##### #{id} #{p.lang} #{p.title} | sub=#{p.title_sub} | meta=#{p.meta_desc} | refs=#{p.references.to_s[0,300]}"; puts p.body[0,1800]; puts}
