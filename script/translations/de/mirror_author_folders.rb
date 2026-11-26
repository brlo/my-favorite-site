# frozen_string_literal: true

# Приводит меню автора к RU-структуре: категории верхнего уровня и раскладка
# уже импортированных трудов по этим категориям.
#   bin/rails runner script/translations/de/mirror_author_folders.rb [APPLY=1]

apply = ARGV.include?('APPLY=1')

AUTHORS = {

  'Johannes_Chrysostomus' => {
    ru: 'Иоанн_Златоуст',
    de: 'Johannes_Chrysostomus',
    folders: {
      'Новозаветные толкования' => ['Neutestamentliche Kommentare', 1],
      'Ветхозаветные толкования' => ['Alttestamentliche Kommentare', 2],
      'Догматические труды' => ['Dogmatische Werke', 3],
      'Пастырские и катехизические' => ['Pastorale und katechetische Werke', 4],
      'Нравственно-аскетические труды' => ['Moralisch-asketische Werke', 5],
      'Праздничные слова и беседы' => ['Festpredigten und Reden', 6],
      'Похвальные слова' => ['Lobrede', 7],
      'Автобиографические беседы и слова' => ['Autobiographische Reden und Homilien', 8],
      'Гомилии на разные случаи' => ['Homilien zu verschiedenen Anlässen', 9],
      'Письма' => ['Briefe', 10],
    },
  },
  'Hieronymus' => {
    ru: 'r6fC_Иероним_Стридонский_IV_век',
    de: 'Hieronymus',
    folders: {
      'Догматико-полемические труды' => ['Dogmatisch-polemische Werke', 1],
      'Экзегетические творения' => ['Exegetische Werke', 2],
      'Исторические труды' => ['Historische Werke', 3],
      'Агиографические труды' => ['Hagiographische Werke', 4],
      'Письма' => ['Briefe', 5],
      'Переводы Священного Писания' => ['Bibelübersetzungen', 6],
    },
  },
  'Cyrill_von_Alexandrien' => {
    ru: 'g1QT_Кирилл_Александрийский_V_век',
    de: 'Cyrill_von_Alexandrien',
    folders: {
      'Экзегетические сочинения' => ['Exegetische Werke', 1],
      'Гомилетические сочинения' => ['Homiletische Werke', 2],
      'Догматико-полемические труды' => ['Dogmatisch-polemische Werke', 3],
      'Послания' => ['Briefe', 4],
      'Spuria (приписываемые)' => ['Spuria (zugeschriebene Schriften)', 100],
    },
  },
  'Johannes_Cassianus' => {
    ru: '49Rq_Иоанн_Кассиан_Римлянин_IVV_вв',
    de: 'Johannes_Cassianus',
    folders: {
      'Собеседования египетских подвижников' => ['Unterredungen mit den Vätern', 1],
      'Нравственно-аскетические труды' => ['Moralisch-asketische Werke', 2],
    },
  },
  'Augustinus_von_Hippo' => {
    ru: 'Аврелий_Августин',
    de: 'Augustinus_von_Hippo',
    folders: {
      'Апологетические сочинения' => ['Apologetische Werke', 1],
      'Догматические сочинения' => ['Dogmatische Werke', 2],
      'Пастырские сочинения' => ['Pastorale Werke', 3],
      'Письма' => ['Briefe', 4],
      'Полемические сочинения' => ['Polemische Werke', 5],
      'Сборники, фрагменты' => ['Sammlungen und Fragmente', 6],
      'Философские и литературные сочинения' => ['Philosophische und literarische Werke', 7],
      'Экзегетические сочинения' => ['Exegetische Werke', 8],
      'Автобиографические сочинения' => ['Autobiographische Werke', 9],
    },
  },
  'Ephraem_der_Syrer' => {
    ru: 'LAUq_Ефрем_Сирин_преподобный_306373',
    de: 'Ephraem_der_Syrer',
    folders: {
      'Творения' => ['Werke', 1],
      'Современные переводы' => ['Moderne Übersetzungen', 2],
      'Нравственно-аскетические труды' => ['Moralisch-asketische Werke', 3],
      'Гимнография' => ['Hymnographie', 4],
      'Священное Писание Ветхого Завета' => ['Altes Testament', 5],
      'Священное Писание Нового Завета' => ['Neues Testament', 6],
      'Сборники, симфонии, указатели' => ['Sammlungen und Register', 7],
    },
  },
  'Epiphanius_von_Salamis' => {
    ru: 'K60r_Епифаний_Кипрский_IV_век',
    de: 'Epiphanius_von_Salamis',
    folders: {
      'Догматико-полемические труды' => ['Dogmatisch-polemische Werke', 1],
      'Библейско-исагогические и экзегетические' => ['Biblisch-isagogische und exegetische Werke', 2],
      'Spuria (приписываемые)' => ['Spuria (zugeschriebene Schriften)', 3],
    },
  },
  'Hilarius_von_Poitiers' => {
    ru: '97nZ_Иларий_Пиктавийский_святитель_315367',
    de: 'Hilarius_von_Poitiers',
    folders: {
      'Догматическое богословие' => ['Dogmatische Theologie', 1],
      'Священное Писание Ветхого Завета' => ['Heilige Schrift des Alten Testaments', 2],
    },
  },
  'Tertullian' => {
    ru: 'тертуллиан',
    de: 'Tertullian',
    folders: {
      'Период церковного творчества — ~196-206 гг.' => ['Periode des kirchlichen Schaffens (~196–206)', 2],
      'Полумонтанизм — 207-212 гг.' => ['Halbmontanismus (207–212)', 3],
      'Монтанистический — 213-220 гг.' => ['Montanismus (213–220)', 4],
    },
  },
  'Gregor_von_Nyssa' => {
    ru: 'Григорий_Нисский',
    de: 'Gregor_von_Nyssa',
    folders: {
      'Догматико-полемические труды' => ['Dogmatisch-polemische Werke', 1],
      'Экзегетические труды' => ['Exegetische Werke', 2],
      'Нравственно-аскетические труды' => ['Moralisch-asketische Werke', 3],
      'Проповеди' => ['Predigten', 4],
      'Письма' => ['Briefe', 5],
      'Dubia (сомнительные)' => ['Dubia (zweifelhafte Schriften)', 99],
    },
  },
  'Basilius_der_Große' => {
    ru: 'mz9h_Василий_Великий_IV_век',
    de: 'Basilius_der_Große',
    folders: {
      'Экзегетические труды' => ['Exegetische Werke', 1],
      'Аскетические труды' => ['Asketische Werke', 2],
      'Гимнография. Каноническое право' => ['Hymnographie und Kirchenrecht', 3],
      'Догматические труды' => ['Dogmatische Werke', 4],
      'Нравственно-аскетические труды' => ['Moralisch-asketische Werke', 5],
      'Письма' => ['Briefe', 6],
      'Молитвы' => ['Gebete', 10],
      'Симфонии или указатели' => ['Symphonien oder Register', 100],
      'Spuria (приписываемые)' => ['Spuria (zugeschriebene Schriften)', 200],
    },
  },
  'Athanasius_der_Große' => {
    ru: 'Афанасий-Великий',
    de: 'Athanasius_der_Große',
    folders: {
      'Апологетические труды' => ['Apologetische Werke', 1],
      'Догматико-полемические труды' => ['Dogmatisch-polemische Werke', 2],
      'Историко-полемические труды' => ['Historisch-polemische Werke', 3],
      'Экзегетические труды' => ['Exegetische Werke', 4],
      'Нравственно-аскетические труды' => ['Moralisch-asketische Werke', 5],
      'Послания' => ['Briefe', 6],
      'Dubia (сомнительные)' => ['Dubia (zweifelhafte Schriften)', 99],
      'Spuria (приписываемые)' => ['Spuria (zugeschriebene Schriften)', 100],
    },
  },
}.freeze

def top_category(menu)
  node = menu
  node = ::Menu.find(node.parent_id) while node.parent_id
  node
end

AUTHORS.each do |de_path, cfg|
  ru_author = ::Page.find_by(lang: 'ru', path: cfg[:ru])
  de_author = ::Page.find_by(lang: 'de', path: cfg[:de])
  next if ru_author.nil? || de_author.nil?
  folders = {}
  cfg[:folders].each do |ru_title, (de_title, priority)|
    folder = ::Menu.find_by(page_id: de_author.id, parent_id: nil, title: de_title)
    if folder.nil?
      puts "создать папку: #{de_title}"
      folder = ::Menu.create!(page_id: de_author.id, title: de_title, priority: priority) if apply
    elsif folder.priority != priority
      folder.update!(priority: priority) if apply
    end
    folders[ru_title] = folder
  end
  next unless apply

  ::Menu.where(page_id: de_author.id).where.not(path: [nil, '']).find_each do |item|
    page = ::Page.find_by(lang: 'de', path: item.path)
    next if page.nil?

    ru_page = ::Page.find_by(lang: 'ru', group_lang_id: page.group_lang_id)
    next if ru_page.nil?

    ru_menu = ::Menu.find_by(page_id: ru_author.id, path: ru_page.path)
    next if ru_menu.nil?

    top = top_category(ru_menu)
    next if top.nil?

    folder = folders[top.title]
    next if folder.nil?

    attrs = { parent_id: folder.id, priority: ru_menu.priority, is_gold: ru_menu.is_gold }
    changed = attrs.reject { |k, v| item.public_send(k) == v }
    unless changed.empty?
      puts "  #{item.title}: -> #{folder.title}"
      item.update!(changed)
    end
  end

  allowed = cfg[:folders].values.map(&:first)
  ::Menu.where(page_id: de_author.id, parent_id: nil).where.not(title: allowed).find_each do |folder|
    folder.destroy if ::Menu.where(parent_id: folder.id).none?
  end
end

puts apply ? 'ПРИМЕНЕНО' : 'DRY RUN (APPLY=1 для записи)'
