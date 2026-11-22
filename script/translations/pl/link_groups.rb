# Привязка латинских страниц к русским группам языков там, где пара уже есть,
# но группа не совпала (например, часть труда получила новую группу при импорте).
#   bin/rails runner script/translations/pl/link_groups.rb [DRY_RUN=1]
require 'json'

dry = ENV['DRY_RUN'].present?
linked = 0
Dir[File.expand_path('authors/*.json', __dir__)].sort.each do |file|
  cfg = JSON.parse(File.read(file))
  lang = cfg['lang'] || 'la'
  cfg['works'].each do |w|
    pairs = if w['parts']
              w['parts'].map { |p| [p['path'], p['ru']] }
            else
              [[w['path'], w['ru']]]
            end
    pairs.each do |la_path, ru_path|
      next if la_path.blank? || ru_path.blank?
      la = ::Page.find_by(lang: lang, path_low: la_path.downcase) ||
           ::Page.where(lang: lang).where("path_low LIKE ?", "#{la_path.downcase}\_%").order(:id).first
      ru = ::Page.find_by(lang: 'ru', path_low: ru_path.downcase)
      next unless la && ru
      next if la.group_lang_id == ru.group_lang_id

      holder = ::Page.find_by(lang: lang, group_lang_id: ru.group_lang_id)
      next if holder && holder.id != la.id

      puts "#{la.path}: группа #{la.group_lang_id} → #{ru.group_lang_id} (#{ru.title})"
      la.update_columns(group_lang_id: ru.group_lang_id) unless dry
      linked += 1
    end
  end
end
puts "привязано страниц: #{linked}"
