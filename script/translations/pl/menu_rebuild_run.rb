# Перестройка меню по конфигам конвейера:
#   bin/rails runner script/translations/pl/menu_rebuild_run.rb [DRY_RUN=1] [AUTHOR=augustinus]
require_relative 'menu_rebuild'

files = Dir[File.expand_path('authors/*.json', __dir__)]
if ENV['AUTHOR'].present?
  files = files.select { |f| File.basename(f, '.json') == ENV['AUTHOR'] }
end
MenuRebuild.run!(files.sort, dry: ENV['DRY_RUN'].present?)
