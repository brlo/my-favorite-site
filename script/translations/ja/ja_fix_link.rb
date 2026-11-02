# bin/rails runner tmp/ja_fix_link.rb OLD NEW — заменить ссылку во всех японских статьях jp_q
old, new = ARGV
list = Page.find_by(lang: 'ja', path_low: 'jp_q')
Page.where(parent_id: list.id, lang: 'ja').find_each do |pg|
  ch = %w[body references].to_h { [_1, pg[_1].to_s.gsub(old, new)] }.select { |f, v| v != pg[f].to_s }
  next if ch.empty?
  Page.without_index_now { pg.update!(ch) }
  puts "fixed #{pg.path}"
end
