# Подготовка японского перевода по английскому YAML: текст en-статьи + jp-ni по каждой ссылке.
# bin/rails runner tmp/prep_ja2.rb db/translations/en/q_god_1.yml [src ...]
require 'yaml'
clean = ->(t) { t.to_s.gsub(/\[[^\]]*\]/, '').gsub(%r{<br>|</?(j|i)>}, '').squeeze(' ').strip }
fetch = lambda do |tr, bk, ch, lines|
  Verse.where(tr_code: tr, book: bk, chapter: ch, line: lines).order(:line).map { |v| "[#{v.line}]#{clean.(v.text)}" }.join(' ')
end
expand = ->(ls) { ls.split(',').flat_map { |x| a, z = x.split('-').map(&:to_i); (a..(z || a)).to_a } }
ja_groups = Page.where(lang: 'ja').pluck(:group_lang_id).to_set

file, *only = ARGV
items =
  if file.start_with?('db:')
    # db:EN_PATH=RU_SRC,... — английская статья из базы (её нет в YAML)
    file.delete_prefix('db:').split(',').map do |pair|
      en_path, ru = pair.split('=')
      pg = Page.find_by!(lang: 'en', path: en_path)
      { 'src' => ru, 'path' => en_path, 'title' => pg.title, 'title_sub' => pg.title_sub, 'meta_desc' => pg.meta_desc,
        'body' => pg.body, 'references' => pg.references }
    end
  else
    YAML.load_file(file)['pages']
  end
items.each do |it|
  next if only.any? && !only.include?(it['src'])
  src = Page.find_by(lang: 'ru', path: it['src'])
  next puts("SKIP (ja есть) #{it['src']}") if src && ja_groups.include?(src.group_lang_id)
  puts "===== src=#{it['src']} | en=#{it['path']} | #{it['title']} | sub=#{it['title_sub']} | meta=#{it['meta_desc']} | menu=#{it['menu']}"
  puts "REFS: #{it['references']}" if it['references'].present?
  puts it['body'].gsub(%r{</(p|blockquote|h\d|li|ul|ol)>}) { "#{$&}\n" }
  puts '----- JP'
  seen = {}
  (it['body'].to_s + it['references'].to_s).scan(%r{bibleox\.com/en/([a-z0-9-]+)/([0-9a-z]+)/(\d+)/?(?:#L([\d,\-]+))?"}).each do |tr, bk, ch, ls|
    next if tr == 'en' || ls.nil? || seen[[bk, ch, ls]]
    seen[[bk, ch, ls]] = true
    lines = expand.(ls)
    next if lines.size > 40
    if bk == 'ps'
      # jp-ni считает надписание стихом: номер стиха бывает больше английского на 1–2
      (0..2).each { |d| t = fetch.('jp-ni', bk, ch.to_i, lines.map { _1 + d }); puts "ps:#{ch}:#{ls} +#{d} JP: #{t}" if t.present? }
    else
      t = fetch.('jp-ni', bk, ch.to_i, lines)
      puts "#{bk}:#{ch}:#{ls}#{tr == 'gr-lxx-byz' ? ' [LXX-link]' : ''} JP: #{t.presence || '-- НЕТ В jp-ni --'}"
    end
  end
  puts
end
