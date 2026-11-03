# STDIN — новое тело страницы: bin/rails runner script/translations/page_update.rb LANG PATH BACKUP_FILE
# Старое тело сохраняется в BACKUP_FILE.
# REFS=файл — заодно заменить примечания (references); старые сохраняются в BACKUP_FILE.refs
lang, path, backup = ARGV
pg = Page.find_by!(lang: lang, path: path)
File.write(backup, pg.body)
attrs = { body: $stdin.read }
if ENV['REFS'].present?
  File.write("#{backup}.refs", pg.references.to_s)
  attrs[:references] = File.read(ENV['REFS'])
end
pg.update!(attrs)
puts "updated #{pg.id} #{pg.path}, #{pg.body.size} chars#{', references' if attrs[:references]}, backup: #{backup}"
