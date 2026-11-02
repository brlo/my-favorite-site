# Переносит обложки на переводы: bin/rails runner script/translations/copy_covers.rb LANG [LIST] [DRY_RUN]
# Берёт обложку русской статьи той же группы, если у перевода своей ещё нет. Без LIST — все страницы языка.
lang, list, dry = ARGV
pages = Page.where(lang: lang).where.not(group_lang_id: [nil, ''])
pages = pages.where(parent_id: Page.find_by!(lang: lang, path_low: list.downcase).id) if list.present?
done = 0
pages.find_each do |page|
  next if page.cover.present?

  ru = Page.find_by(lang: 'ru', group_lang_id: page.group_lang_id)
  next if ru.nil? || ru.cover.blank?

  puts "#{page.path} <- #{ru.path}"
  TranslationImporter.copy_cover(ru, page) unless dry
  done += 1
end
puts "обложек: #{done}"
