%w[Man World Old\ Testament Parables Angels Prophecies Sin Afterlife Virtue Prototypes Law Worship Holy Fallen].each do |t|
  Menu.where(title: t).each { |m| puts [m.id, m.title, m.priority, m.parent_id, m.page_id].inspect }
end
