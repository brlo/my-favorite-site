Page.where(lang: %w[ko hi zh-Hans]).order(:lang,:id).each{|p| puts [p.id,p.lang,p.path,p.title,p.group_lang_id,p.parent_id,p.page_type,p.body.size,p.updated_at.to_date].join(" | ")}
puts "--"
Page.where(group_lang_id: "65bdfc1adba7720001ec3b95").each{|p| puts [p.id,p.lang,p.path,p.title].join(" | ")}
puts "-- ja 827 children"; Page.where(parent_id: 827).each{|p| puts [p.id,p.path,p.title,p.group_lang_id,Page.where(parent_id:p.id).count].join(" | ")}
