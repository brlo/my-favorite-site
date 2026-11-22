# Запуск упрощения меню латинских авторов:
#   bin/rails runner script/translations/pl/menu_tidy_run.rb [DRY_RUN=1] [AUTHOR=path]
require_relative 'menu_tidy'

MenuTidy.run!(dry: ENV['DRY_RUN'].present?, author_path: ENV['AUTHOR'].presence)
