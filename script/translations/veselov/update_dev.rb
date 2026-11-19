# Update EN body of a Veselov page in DEV database.
# Usage: PID=<page_id> FILE=/app/tmp/body_en_<ru_id>.html bin/rails runner /app/tmp/veselov_update_dev.rb
# Keeps backup of the previous body. Dev only — never run on prod as-is.
page = Page.find(ENV.fetch("PID").to_i)
new_body = File.read(ENV.fetch("FILE"))

backup = "/app/tmp/veselov_backup_dev_#{page.id}.html"
File.write(backup, page.body) unless File.exist?(backup)

page.update!(body: new_body)
puts "page #{page.id} updated: #{page.body.length} chars, backup: #{backup}"
