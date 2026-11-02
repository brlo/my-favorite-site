# bin/rails runner script/translations/chk_q.rb LANG FILE — стихи существуют и не пусты, подписи ссылок совпадают с локалью
lang, f = ARGV
short = I18n.t('books.short', locale: lang.to_sym)
s = File.read(f)
bad = s.scan(%r{/#{lang}/([a-z0-9-]+)/([0-9a-z]+)/(\d+)/(?:#L([\d,\-]+))?">(?:<em>)?([^<]+)<}).filter_map do |tr, bk, ch, ls, label|
  lab = label[/\A\S+/]; errs = []
  errs << "label #{lab}≠#{short[bk.to_sym]}" if short[bk.to_sym] && lab != short[bk.to_sym] && lab !~ /\A\d/
  nums = ls ? ls.split(',').flat_map { |x| a, z = x.split('-').map(&:to_i); (a..(z || a)).to_a } : [1]
  have = Verse.where(tr_code: tr, book: bk, chapter: ch.to_i, line: nums).where("length(trim(text)) > 2").pluck(:line)
  errs << "missing #{nums - have}" if (nums - have).any?
  "#{tr}/#{bk}/#{ch}#L#{ls}: #{errs.join(', ')}" if errs.any?
end
puts bad.uniq, "checked"
