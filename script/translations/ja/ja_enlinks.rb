# Ссылки из японских статей jp_q на английские статьи (en/en/w/...): какие из них — переводы раздела en-q
list = Page.find_by(lang: 'ja', path_low: 'jp_q')
enq = Page.find_by(lang: 'en', path_low: 'en-q')
Page.where(parent_id: list.id, lang: 'ja').find_each do |pg|
  (pg.body.to_s + pg.references.to_s).scan(%r{bibleox\.com/en/en/w/([^"/#]+)}).flatten.uniq.each do |p|
    en = Page.find_by(lang: 'en', path_low: CGI.unescape(p).downcase)
    next puts("#{pg.path}: #{p} — НЕТ en") unless en
    next unless en.parent_id == enq.id
    ru = Page.find_by(lang: 'ru', group_lang_id: en.group_lang_id)
    puts "#{pg.path}: #{p} -> ru #{ru&.path}"
  end
end
