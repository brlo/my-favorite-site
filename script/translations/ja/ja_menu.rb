# Дерево японского меню (page_id 569 — список jp_q)
def show(m, d) = (puts "#{'  ' * d}#{m.id} [#{m.priority}] #{m.title} -> #{m.path.presence || '-'}"; Menu.where(parent_id: m.id).order(:priority, :id).each { show(_1, d + 1) })
Menu.where(page_id: 569, parent_id: nil).order(:priority, :id).each { show(_1, 0) }
