# STDIN — новое тело страницы: bin/rails runner script/translations/page_update.rb LANG PATH BACKUP_FILE
# Старое тело сохраняется в BACKUP_FILE.
lang, path, backup = ARGV
pg = Page.find_by!(lang: lang, path: path)
File.write(backup, pg.body)
pg.update!(body: $stdin.read)
puts "updated #{pg.id} #{pg.path}, #{pg.body.size} chars, backup: #{backup}"
