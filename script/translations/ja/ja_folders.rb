# bin/rails runner tmp/ja_folders.rb 'PARENT_PATH' 'title:priority' ... — создать папки в японском меню jp_q (page_id 569)
parent_path, *items = ARGV
parent = parent_path.split('/').inject(nil) { |pid, t| Menu.find_by!(page_id: 569, parent_id: pid, title: t).id }
items.each do |it|
  t, pr = it.split(':')
  m = Menu.find_or_create_by!(page_id: 569, parent_id: parent, title: t) { _1.priority = pr.to_i }
  puts "#{m.id} #{parent_path}/#{t} [#{m.priority}]"
end
