# Выгрузка стихов для перевода: RU (Синодальный) vs gr-lxx-byz, по ссылкам RU-статьи.
#   bin/rails runner tmp/el_quotes/verses.rb <ru_path>   → tmp/el_quotes/verses_<path>.txt
path = ARGV[0] or abort 'usage: verses.rb <ru_path>'
pg = Page.find_by(lang: 'ru', path: path) or abort "нет статьи #{path}"
b = pg.body.to_s

refs = b.scan(%r{(?:bibleox\.com)?/ru/(?:ru/)?([a-z0-9-]+)/(\d+)/?(?:#L([\d,\-]+))?})
        .map { |bk, ch, ls| [bk, ch.to_i, ls] }
        .reject { |bk, ch, _| bk.nil? || ch.zero? }
        .uniq

def expand(ls) = ls.to_s.split(',').flat_map { |x| a, z = x.split('-').map(&:to_i); (a..(z || a)).to_a }

out = +""
refs.sort_by { |bk, ch, _| [bk, ch] }.each do |bk, ch, ls|
  nums = ls.nil? ? [] : expand(ls)
  ru = Verse.where(tr_code: 'ru', book: bk, chapter: ch).pluck(:line, :text).to_h
  gr = Verse.where(tr_code: 'gr-lxx-byz', book: bk, chapter: ch).pluck(:line, :text).to_h
  show = nums.empty? ? (ru.keys | gr.keys).sort : nums
  out << "\n===== #{bk} #{ch}:#{ls} =====\n"
  show.each do |n|
    out << "  [#{n}] RU: #{ru[n].to_s.strip}\n"
    out << "  [#{n}] GR: #{gr[n].to_s.strip}\n"
  end
end
File.write("tmp/el_quotes/verses_#{path}.txt", out)
puts "#{refs.size} ссылок → tmp/el_quotes/verses_#{path}.txt"
