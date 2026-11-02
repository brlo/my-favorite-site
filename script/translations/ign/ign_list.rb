pats = %w[ΙγνΘ% ИгнАн% IgnAn% mlNq% ahBy%]
Page.where("path LIKE ANY (array[?])", pats).order(:lang,:path).each{|p| puts [p.id,p.lang,p.path,p.title,p.group_lang_id,p.parent_id,p.is_published,p.body.to_s.size, p.updated_at.to_date].join(" | ")}
puts "---"
g = Page.where("path LIKE ?", "ИгнАн%").pluck(:group_lang_id)
Page.where(group_lang_id: g).where.not(lang: %w[ru]).order(:group_lang_id,:lang).each{|p| puts [p.id,p.lang,p.path,p.title,p.group_lang_id,p.body.to_s.size,p.updated_at.to_date].join(" | ")}
