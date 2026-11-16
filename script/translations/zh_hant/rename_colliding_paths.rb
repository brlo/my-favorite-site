# zh-Hant: пути, совпавшие с упрощённым написанием (path_low уникален глобально),
# переименовать A_ → T_ (QY5A_假基督 → QY5T_假基督).
# Запускать ПОСЛЕ последнего q_build: q_build перегенерирует yml и затирает переименования.
# Usage: bin/rails runner script/translations/zh_hant/rename_colliding_paths.rb [LANG=zh-Hant]
lang = ARGV.find { |a| a.start_with?('LANG=') }&.sub('LANG=', '') || 'zh-Hant'
Dir["db/translations/#{lang}/q_*.yml"].each do |f|
  y = YAML.safe_load(File.read(f), permitted_classes: [], aliases: true)
  changed = false
  y['pages'].each do |p|
    # коллизия — только если путь занят страницей ДРУГОГО языка (свои страницы
    # на этом языке находятся сами собой и не повод переименовывать)
    next unless ::Page.where(path_low: p['path'].downcase).where.not(lang: lang).exists?
    np = p['path'].sub(/A(?=_)/, 'T')
    next if np == p['path'] || ::Page.where(path_low: np.downcase).where.not(lang: lang).exists?
    puts "#{p['path']} → #{np}"
    p['path'] = np
    changed = true
  end
  File.write(f, y.to_yaml(line_width: -1)) if changed
end
puts :done
