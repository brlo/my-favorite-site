# Единая структура меню раздела «Предание» (страницы links_<locale>).
#
# Эталон — русское меню links_ru: три группы, в «Библиотеке» девять пунктов,
# в «Цитатниках» два, в «Статьях» один. Между языками структура не должна
# отличаться; переводятся только названия, а путь пункта берётся у страницы
# перевода по group_lang_id. Если раздела на языке ещё нет — пункт-заготовка
# без path (серая подпись в меню), как в zh-Hans.
#
# Проверка всех языков (ничего не пишет, exit 1 при отклонениях):
#   bin/rails runner script/translations/links_structure.rb
# Проверка/план одного языка:
#   bin/rails runner script/translations/links_structure.rb LANG=zh-Hant
# Выравнивание языка (пишет в БД):
#   bin/rails runner script/translations/links_structure.rb LANG=zh-Hant APPLY=1
#
# Чтобы выровнять новый язык, добавьте его названия в TITLES (ключи — из
# TEMPLATE, эмодзи сохраняем) и прогоните APPLY=1. Перед этим посмотрите план
# без APPLY: скрипт не удаляет лишние пункты и не переименовывает уже
# существующие — только создаёт недостающие, переносит к правильному родителю,
# проставляет priority и заполняет path у заготовок.
TEMPLATE = [
  {
    key: :library, title: 'Библиотека', children: [
      { key: :church_writers, title: '📚 Труды древних святых отцов и церковных писателей', path: 'church_writers' },
      { key: :councils, title: '📃 Соборы', path: 'Вселенские_Соборы' },
      { key: :icons, title: '🖼️ Иконы', path: 'древние-иконы' },
      { key: :churches, title: '🪨 Храмы', path: 'Древние_христианские_храмы' },
      { key: :burials, title: 'Христианские захоронения и надписи', path: 'KPgB_Христианские_захоронения_и_надписи' },
      { key: :manuscripts, title: '📜 Библейские манускрипты', path: 'библейские_манускрипты' },
      { key: :prayers, title: '🙏 Молитвы', path: 'молитвы' },
      { key: :music, title: '🎵 Музыка', path: 'православная_музыка' },
      { key: :kitchen, title: '🍞 Постная кухня', path: '2NCD_Постная_кухня' }
    ]
  },
  {
    key: :quotes, title: 'Цитатники', children: [
      { key: :biblical_quotes, title: '📜 Цитаты библейские', path: 'q' },
      { key: :fathers_quotes, title: '📖 Цитаты святых отцов', path: 'q-saints' }
    ]
  },
  {
    key: :articles, title: 'Статьи о Писании и Предании', children: [
      { key: :authors, title: '📄 Авторские публикации', path: 'authors' }
    ]
  }
].freeze

# Названия пунктов по языкам. Ключи — из TEMPLATE.
TITLES = {
  'fr' => {
    library: 'Bibliothèque',
    church_writers: '📚 Ouvrages des anciens chrétiens',
    councils: '📃 Conciles',
    icons: '🖼️ Icônes',
    churches: '🪨 Temples',
    burials: 'Sépultures et inscriptions chrétiennes',
    manuscripts: '📜 Manuscrits bibliques',
    prayers: '🙏 Prières',
    music: '🎵 Musique',
    kitchen: '🍞 Cuisine de carême',
    quotes: 'Recueils de citations',
    biblical_quotes: '📜 Citations bibliques',
    fathers_quotes: "📖 Citations des Pères de l'Église",
    articles: "Articles sur l'Écriture et la Tradition",
    authors: '📄 Publications d’auteurs'
  },
  'zh-Hant' => {
    library: '圖書館',
    church_writers: '📚 古代基督教著作',
    councils: '📃 大公會議',
    icons: '🖼️ 古代聖像集',
    churches: '🪨 古代基督教教堂',
    burials: '基督徒的墓葬與銘文',
    manuscripts: '📜 聖經手抄本',
    prayers: '🙏 祈禱文',
    music: '🎵 聖樂',
    kitchen: '🍞 守齋飲食',
    quotes: '語錄集',
    biblical_quotes: '📜 聖經引文',
    fathers_quotes: '📖 教父語錄',
    articles: '關於聖經與傳統的文章',
    authors: '📄 作者專欄'
  },
  'ar' => {
    library: 'المكتبة',
    church_writers: '📚 مؤلفات المسيحيين الأوائل',
    councils: '📃 المجامع المسكونية',
    icons: '🖼️ الأيقونات',
    manuscripts: '📜 مخطوطات الكتاب المقدس',
    prayers: '🙏 صلوات',
    music: '🎵 موسيقى كنسية',
    churches: '🪨 الكنائس المسيحية القديمة',
    burials: 'المقابر والنقوش المسيحية',
    kitchen: '🍞 المطبخ الصيامي',
    quotes: 'مجموعات اقتباسات',
    biblical_quotes: '📜 اقتباسات من الكتاب المقدس',
    fathers_quotes: '📖 اقتباسات من آباء القديسين',
    articles: 'مقالات عن الكتاب المقدس والتقليد',
    authors: '📄 منشورات كاتبي الموقع'
  },
  'es' => {
    library: 'Biblioteca',
    church_writers: '📚 Obras de los antiguos cristianos',
    councils: '📃 Concilios',
    icons: '🖼️ Iconos',
    manuscripts: '📜 Manuscritos bíblicos',
    prayers: '🙏 Oraciones',
    music: '🎵 Música',
    churches: '🪨 Templos cristianos antiguos',
    burials: 'Enterramientos e inscripciones cristianas',
    kitchen: '🍞 Cocina de ayuno',
    quotes: 'Colecciones de citas',
    biblical_quotes: '📜 Citas bíblicas',
    fathers_quotes: '📖 Citas de los Santos Padres',
    articles: 'Artículos sobre la Escritura y la Tradición',
    authors: '📄 Publicaciones de autores'
  },
  'fa' => {
    library: 'کتابخانه',
    church_writers: '📚 آثار قدیسین باستان و نویسندگان کلیسایی',
    councils: '📃 شوراها',
    icons: '🖼️ آیکون‌ها',
    manuscripts: '📜 نسخه‌های خطی کتاب مقدس',
    prayers: '🙏 دعاها',
    music: '🎵 موسیقی',
    churches: '🪨 کلیساهای باستانی مسیحی',
    burials: 'آرامگاه‌ها و کتیبه‌های مسیحی',
    kitchen: '🍞 آشپزی روزه‌داری',
    quotes: 'مجموعه‌ی نقل‌قول‌ها',
    biblical_quotes: '📜 نقل‌قول‌های کتاب مقدس',
    fathers_quotes: '📖 نقل‌قول‌های قدیسین',
    articles: 'مقالات درباره‌ی کتاب مقدس و سنّت',
    authors: '📄 انتشارات نویسندگان'
  },
  'hi' => {
    library: 'पुस्तकालय',
    church_writers: '📚 प्राचीन ईसाई संतों के ग्रंथ',
    councils: '📃 चर्च काउंसिल',
    icons: '🖼️ आइकॉन',
    manuscripts: '📜 बाइबिल की पांडुलिपियाँ',
    prayers: '🙏 प्रार्थनाएँ',
    music: '🎵 संगीत',
    churches: '🪨 प्राचीन ईसाई गिरजाघर',
    burials: 'ईसाई कब्रें और शिलालेख',
    kitchen: '🍞 उपवास का भोजन',
    quotes: 'उद्धरण संग्रह',
    biblical_quotes: '📜 बाइबिल के उद्धरण',
    fathers_quotes: '📖 पवित्र पिताओं के उद्धरण',
    articles: 'शास्त्र और परंपरा पर लेख',
    authors: '📄 लेखक के प्रकाशन'
  }
}.freeze

def links_page(lang)
  ::Page.find_by(lang: lang, path_low: "links_#{lang.downcase}")
end

# Путь перевода страницы RU-эталона; nil — перевода (и его пункта) ещё нет.
def translated_path(lang, ru_path)
  ru = ::Page.find_by(lang: 'ru', path: ru_path)
  return if ru&.group_lang_id.blank?

  ::Page.where(lang: lang, group_lang_id: ru.group_lang_id).pick(:path)
end

def menu_tree(page)
  roots = ::Menu.where(page_id: page.id, parent_id: nil).order(:priority, :id).to_a
  roots.map { |root| [root, ::Menu.where(parent_id: root.id).order(:priority, :id).to_a] }
end

def report_structure(lang, page)
  tree = menu_tree(page)
  shape = tree.map { |root, children| children.size }
  expected = TEMPLATE.map { |node| node[:children].size }
  roots_with_path = tree.flat_map(&:first).select { |menu| menu.path.present? }
  nested = tree.flat_map { |_, children| children }.select { |menu| ::Menu.where(parent_id: menu.id).exists? }
  problems = []
  problems << "корней #{tree.size}, нужно #{TEMPLATE.size}" if tree.size != TEMPLATE.size
  problems << "пунктов в группах #{shape.inspect}, нужно #{expected.inspect}" if shape != expected
  problems << "у корневой группы есть path: #{roots_with_path.map(&:title).inspect}" if roots_with_path.any?
  problems << "третий уровень вложенности: #{nested.map(&:title).inspect}" if nested.any?

  if problems.empty?
    puts "== #{lang}: OK (#{shape.join('/')})"
    true
  else
    puts "== #{lang}: ОТКЛОНЕНИЕ — #{problems.join('; ')}"
    tree.each do |root, children|
      puts "   #{root.title} -> #{root.path.presence || '-'} [#{root.priority}]"
      children.each { |menu| puts "     #{menu.title} -> #{menu.path.presence || '-'} [#{menu.priority}]" }
    end
    false
  end
end

def check_all
  langs = ::Page.where("path_low LIKE 'links\\_%'").pluck(:lang).sort
  deviations = langs.reject do |lang|
    page = links_page(lang)
    if page.nil?
      puts "== #{lang}: нет страницы links_#{lang.downcase}"
      false
    else
      report_structure(lang, page)
    end
  end
  puts
  puts deviations.any? ? "Отклонения: #{deviations.join(', ')}" : 'Все меню соответствуют эталону.'
  exit(deviations.any? ? 1 : 0)
end

# is_write включается и для плана: план считается в транзакции с откатом,
# иначе новые группы не видны их будущим детям и «лишними» кажутся пункты,
# которые на самом деле переедут в новую группу.
def align(lang, is_write, is_apply)
  page = links_page(lang) or abort "нет страницы links_#{lang.downcase}"
  titles = TITLES[lang] or abort "нет названий для #{lang}: добавьте язык в TITLES"

  changes = []
  seen_ids = []
  walk = lambda do |nodes, parent|
    nodes.each_with_index do |node, index|
      title = titles.fetch(node[:key])
      path = node[:path] && translated_path(lang, node[:path])
      menu = (path.present? && ::Menu.find_by(page_id: page.id, path: path)) ||
             ::Menu.find_by(page_id: page.id, title: title)

      if menu
        seen_ids << menu.id
        if path.present? && menu.path.blank?
          changes << "path: #{title} #{menu.path.inspect} -> #{path.inspect}"
          menu.path = path
        elsif path.present? && menu.path != path
          puts "! #{title}: в меню путь #{menu.path.inspect}, у перевода #{path.inspect} — путь не меняю"
        elsif path.blank? && menu.path.present?
          puts "! #{title}: в меню путь #{menu.path.inspect}, но перевода нет — путь не меняю"
        end
        desired_parent = parent&.id
        if menu.parent_id != desired_parent
          changes << "parent: #{title} #{menu.parent_id.inspect} -> #{desired_parent.inspect}"
          menu.parent_id = desired_parent
        end
        if menu.priority != index + 1
          changes << "priority: #{title} #{menu.priority} -> #{index + 1}"
          menu.priority = index + 1
        end
        menu.save! if is_write && menu.changed?
      else
        changes << "create: #{title} -> #{path.presence || '-'} [#{index + 1}]"
        next unless is_write

        menu = ::Menu.create!(
          page_id: page.id, parent_id: parent&.id, title: title, path: path.presence, priority: index + 1
        )
        seen_ids << menu.id
      end

      walk.call(node[:children], menu) if menu && node[:children].present?
    end
  end
  walk.call(TEMPLATE, nil)

  extra = ::Menu.where(page_id: page.id).where.not(id: seen_ids).to_a
  extra.each { |menu| puts "! лишний пункт меню (не удаляю): #{menu.title} -> #{menu.path.inspect} [#{menu.priority}]" }

  puts "#{is_apply ? 'ВЫПОЛНЕНО' : 'ПЛАН'} (#{lang}): изменений #{changes.size}"
  changes.each { |change| puts "  #{change}" }
  report_structure(lang, page) if is_write
end

lang = ARGV.find { |arg| arg.start_with?('LANG=') }&.sub('LANG=', '')
is_apply = ARGV.include?('APPLY=1')

if lang
  if is_apply
    align(lang, true, true)
  else
    # План: те же операции в транзакции, но без сохранения.
    ::ActiveRecord::Base.transaction do
      align(lang, true, false)
      raise ::ActiveRecord::Rollback
    end
    puts 'ПЛАН не записан (для записи добавьте APPLY=1)'
  end
else
  abort 'APPLY=1 требует LANG=<язык>' if is_apply
  check_all
end
