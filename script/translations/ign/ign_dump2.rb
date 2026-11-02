[138,144,141].each{|id| p=Page.find(id); puts [p.id,p.lang,p.path,p.title,p.group_lang_id,p.parent_id, p.parent&.path, p.page_type, p.body.size].join(" | ")}
puts "-- group of ja person"
Page.where(group_lang_id: "65a6a542dba77200015a5fdf").each{|p| puts [p.id,p.lang,p.path,p.title,p.parent_id,p.parent&.path,p.page_type,p.body.size, Page.where(parent_id:p.id).count].join(" | ")}
puts "-- langs ko hi zh: chirch writers lists"
Page.where(lang: %w[ko hi zh ja], page_type: Page.find(138).page_type).limit(0)
Page.where("path ILIKE ?", "%chirch%").each{|p| puts [p.id,p.lang,p.path,p.title,p.group_lang_id, Page.where(parent_id:p.id).count].join(" | ")}
puts Page.group(:lang).count.inspect
