[138,144,141,1208,951].each{|id| puts "## #{id}"; Menu.where(page_id: id).order(:priority).each{|m| puts [m.id,m.parent_id,m.title,m.path,m.priority,m.is_empty].join(" | ")}}
puts "## menus pointing to ja 951 / ru 138"; Menu.where(path: [Page.find(951).path, Page.find(138).path]).each{|m| puts [m.id,m.page_id,Page.find(m.page_id).path,m.parent_id,m.title].join(" | ")}
puts "## ko list 1130"; Menu.where(page_id: 1130).order(:priority).each{|m| puts [m.id,m.parent_id,m.title,m.path,m.priority].join(" | ")}
puts "## zh 2812"; Menu.where(page_id: 2812).each{|m| puts [m.id,m.parent_id,m.title,m.path,m.priority].join(" | ")}
puts "## hi 1358"; Menu.where(page_id: 1358).each{|m| puts [m.id,m.parent_id,m.title,m.path,m.priority].join(" | ")}
puts Page.column_names.include?("is_menu_icons")
