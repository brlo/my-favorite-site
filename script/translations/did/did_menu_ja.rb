# Дидахе есть в меню японского раздела авторов дважды: в «1世紀 → 1世紀の無名の作者による作品» (страница-список,
# заполняет импорт did_00/did_01) и в «カテキズム» — там пустая заготовка «ディダケー（1世紀～2世紀）», её ведём на перевод.
#   bin/rails runner script/translations/did/did_menu_ja.rb [DRY_RUN=1]
PATH = 'Dd1A_ディダケー十二使徒の教え'

abort "нет японского перевода Дидахе (#{PATH})" unless Page.exists?(lang: 'ja', path: PATH)
list = Page.find_by!(lang: 'ja', path: 'chirch_writers_jp')
folder = Menu.find_by!(page_id: list.id, parent_id: nil, title: 'カテキズム')
stub = Menu.find_by(page_id: list.id, parent_id: folder.id, title: 'ディダケー（1世紀～2世紀）')
abort 'нет заготовки «ディダケー（1世紀～2世紀）» в разделе カテキズム' unless stub
if stub.path == PATH
  puts 'уже заполнено'
elsif stub.path.present?
  abort "заготовка уже ведёт на #{stub.path}"
else
  stub.update!(path: PATH) unless ENV['DRY_RUN'].present?
  puts "#{ENV['DRY_RUN'].present? ? '[DRY RUN] ' : ''}カテキズム → ディダケー（1世紀～2世紀）: #{PATH}"
end
