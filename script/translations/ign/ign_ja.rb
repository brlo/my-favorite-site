p = Page.find(951); puts p.body; puts "=== children"; Page.where(parent_id: 951).each{|c| puts [c.id,c.path,c.title,c.body.size].join(" | ")}
puts "=== parent"; puts p.parent&.path
