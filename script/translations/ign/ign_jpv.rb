ARGV_REFS = ENV['REFS'].split(';')
ARGV_REFS.each{|r| b,c,vs=r.split(':'); vs=vs.split(',').map(&:to_i); Verse.where(tr_code:'jp-ni',book:b,chapter:c.to_i,line:vs).order(:line).each{|v| puts "#{b} #{c}:#{v.line} #{v.text_search[0,80]}"}}
