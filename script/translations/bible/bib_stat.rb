%w[jp-ni cn-ccbs en-nrsv ru].each{|t| q=Verse.where(tr_code:t); puts "#{t}: #{q.count} verses, books=#{q.distinct.count(:book)}, lang=#{q.first.lang}, data_sample=#{q.where.not(data: {}).first&.data.inspect.to_s[0,200]}"; v=q.where(book:'ps',chapter:23).order(:line).first; puts "  ps23:1 #{v&.text.to_s[0,80]} | addr=#{v&.address} book_id=#{v&.book_id}"}
puts Verse.where(tr_code:'jp-ni').distinct.pluck(:book).sort.join(' ')
v=Verse.where(tr_code:'jp-ni', book:'mf', chapter:1, line:1).first; puts v.attributes.except('text_tsvector').inspect
