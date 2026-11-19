# Подготовка партии раздела цитат: выгрузка RU-эталона, текущего перевода и ссылок.
#
#   bin/rails runner script/translations/q_batch.rb export LANG TARGET_LIST FOLDER [DIR]
#
# FOLDER — название папки RU-меню (точное или часть, регистр не важен).
# DIR    — куда выгружать (по умолчанию tmp/q_batch/<slug папки>).
#
# Пишет:
#   DIR/meta.tsv          — path RU, path EN (если перевод есть), title, КБ, цитат
#   DIR/ru/<RU path>.html — тело RU-статьи из БД (эталон)
#   DIR/en_orig/<EN path>.html — текущее тело перевода (если есть)
#   DIR/links/<RU path>.txt    — ссылки RU, кандидаты EN-ссылок на стихи и страницы библиотеки
#
# Дальше исполнители пишут DIR/out/<EN path>.html; проверка —
#   q_parity.rb LANG YAML --draft DIR/out
# сборка в YAML — q_apply.rb LANG YAML DIR
require 'fileutils'
require 'cgi'

lang, target, folder_query, out_dir = ARGV[1..]
abort 'usage: q_batch.rb export LANG TARGET_LIST FOLDER [DIR]' unless lang && target && folder_query

ru_list = Page.find_by(lang: 'ru', path_low: 'q-saints') or abort 'нет RU-списка q-saints'
target = Page.find_by(lang: lang, path_low: target.downcase) or abort "нет списка #{target} (lang=#{lang})"
menus = Menu.where(page_id: ru_list.id).to_a
by_parent = menus.group_by(&:parent_id)

# Ищем папку по названию (сначала точное совпадение, потом подстрока).
folders = menus.select { |m| m.path.nil? && m.parent_id.present? || m.path.nil? }
folder = folders.find { |m| m.title.casecmp(folder_query).zero? } ||
         folders.find { |m| m.title.downcase.include?(folder_query.downcase) } or abort "папка не найдена: #{folder_query}"

articles = []
walk = lambda do |parent_id|
  (by_parent[parent_id] || []).sort_by { |m| [m.priority.to_i, m.id] }.each do |m|
    if m.path.present?
      ru = Page.find_by(lang: 'ru', path: m.path)
      articles << [m, ru] if ru && ru.body.to_s.strip.length >= 40
    else
      walk.(m.id)
    end
  end
end
walk.(folder.id)
abort "в папке нет статей: #{folder.title}" if articles.empty?

slug = folder.title.downcase.gsub(/[^a-zа-яё0-9]+/i, '-').gsub(/\A-|-\z/, '')[0, 60]
dir = out_dir || File.join('tmp', 'q_batch', slug)
FileUtils.mkdir_p(File.join(dir, 'ru'))
FileUtils.mkdir_p(File.join(dir, 'en_orig'))
FileUtils.mkdir_p(File.join(dir, 'links'))
FileUtils.mkdir_p(File.join(dir, 'out'))

SHORT = I18n.t('books.short', locale: lang.to_sym).transform_keys(&:to_s)
en_by_group = Page.where(lang: lang, group_lang_id: articles.map { _1[1].group_lang_id }.compact).index_by(&:group_lang_id)

def norm_label(s) = s.to_s.gsub('.', '').gsub(/[\u00a0\u2009\u200a\s]+/, ' ').strip

meta = []
articles.each do |menu, ru|
  en = en_by_group[ru.group_lang_id]
  File.write(File.join(dir, 'ru', "#{ru.path}.html"), ru.body.to_s)
  File.write(File.join(dir, 'en_orig', "#{en.path}.html"), en.body.to_s) if en && en.body.to_s.strip.length >= 40

  lines = ["== #{ru.path} | #{ru.title}"]
  ru.body.to_s.scan(%r{<a [^>]*href="([^"]+)"[^>]*>(.*?)</a>}m) do |href, txt|
    lines << "RU link: #{href} || #{txt.gsub(/<[^>]+>/, '')}"
  end
  seen = {}
  ru.body.to_s.scan(%r{<a [^>]*href="https://bibleox\.com/ru/ru/([a-z0-9]+)/(\d+)/?(?:#L([\d,\-]+))?"[^>]*>(.*?)</a>}m) do |bk, ch, ls, txt|
    next if %w[ru en w].include?(bk)
    next if seen[[bk, ch, ls]]; seen[[bk, ch, ls]] = true
    code = bk == 'prsir' ? 'en-nrsv' : 'eng-nkjv'
    label = "#{bk == 'prsir' ? 'Sir.' : norm_label(SHORT[bk])} #{ch}:#{ls}"
    href = "https://bibleox.com/#{lang}/#{code}/#{bk}/#{ch}/#{ls ? "#L#{ls}" : ''}"
    lines << "bible: #{bk} #{ch}:#{ls} (ru: #{txt.gsub(/<[^>]+>/, '')}) -> <a href=\"#{href}\">#{label}</a>"
  end
  lines << 'bible: (нет) если пусто выше'
  File.write(File.join(dir, 'links', "#{ru.path}.txt"), lines.join("\n") + "\n")

  kb = (ru.body.to_s.size / 1024.0).round
  meta << [ru.path, en&.path.to_s, ru.title.gsub("\t", ' '), kb, ru.body.to_s.scan(/<blockquote/).size].join("\t")
end
File.write(File.join(dir, 'meta.tsv'), "ru_path\ten_path\ttitle\tkb\tquotes\n#{meta.join("\n")}\n")
puts "партия: #{folder.title} — статей #{articles.size}, выгружено в #{dir}"
puts meta
puts "дальше: исполнители пишут #{dir}/out/<EN path>.html; проверка q_parity.rb ... --draft #{dir}/out"
