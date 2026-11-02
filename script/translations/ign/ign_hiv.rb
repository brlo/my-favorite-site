ARGV_REFS = ENV['REFS'].split(';')
ARGV_REFS.each{|r| b,c,vs=r.split(':'); vs=vs.split(',').map(&:to_i); Verse.where(tr_code:'hi-ov',book:b,chapter:c.to_i,line:vs).order(:line).each{|v| puts "#{b} #{c}:#{v.line} #{v.text_search[0,80]}"}}
