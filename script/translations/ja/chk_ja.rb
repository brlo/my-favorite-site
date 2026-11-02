short = I18n.t('books.short', locale: :ja)
s = File.read(ARGV[0] || 'db/translations/ja/q_pilot.yml')
bad = s.scan(%r{/ja/([a-z0-9-]+)/([0-9a-z]+)/(\d+)/(?:#L([\d,\-]+))?"><?(?:em>)?([^<]+)<}).filter_map do |tr, bk, ch, ls, label|
  lab = label.split('.').first.strip
  errs = []
  errs << "label #{lab}≠#{short[bk.to_sym]}" if short[bk.to_sym] && lab != short[bk.to_sym]
  nums = ls ? ls.split(',').flat_map { |x| x.split('-').map(&:to_i) }.uniq : [1]
  miss = nums.reject { |l| Verse.where(tr_code: tr, book: bk, chapter: ch.to_i, line: l).exists? }
  errs << "missing #{miss}" if miss.any?
  "#{tr}/#{bk}/#{ch}#L#{ls}: #{errs.join(', ')}" if errs.any?
end
puts bad.uniq, "checked"
