# Упрощение меню латинских авторов, у которых нет конфига конвейера
# (для авторов из authors/*.json меню строит menu_reset.rb / menu_rebuild_run.rb).
#   bin/rails runner script/translations/pl/menu_tidy_run.rb [DRY_RUN=1] [AUTHOR=path]
require 'json'
require_relative 'menu_tidy'

configured = Dir[File.expand_path('authors/*.json', __dir__)].map do |f|
  JSON.parse(File.read(f)).dig('author', 'path').to_s
end

MenuTidy.run!(dry: ENV['DRY_RUN'].present?, author_path: ENV['AUTHOR'].presence, skip_paths: configured)
MenuTidy.normalize_titles!(dry: ENV['DRY_RUN'].present?)
