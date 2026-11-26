# frozen_string_literal: true

# Приводит меню автора к RU-структуре: категории верхнего уровня и раскладка
# уже импортированных трудов по этим категориям.
#   bin/rails runner script/translations/de/mirror_author_folders.rb [APPLY=1]

apply = ARGV.include?('APPLY=1')

AUTHORS = {
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
  ru_author = ::Page.find_by!(lang: 'ru', path: cfg[:ru])
  de_author = ::Page.find_by!(lang: 'de', path: cfg[:de])
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

  old = ::Menu.find_by(page_id: de_author.id, parent_id: nil, title: 'Werke')
  old.destroy if old && ::Menu.where(parent_id: old.id).none?
end

puts apply ? 'ПРИМЕНЕНО' : 'DRY RUN (APPLY=1 для записи)'
