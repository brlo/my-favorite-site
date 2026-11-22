# Привязка русских страниц-продолжений («…#2», «…#3», отдельные письма/проповеди)
# к латинским страницам того же труда: группа языка русской страницы достаётся
# латинской странице, начиная с которой идёт соответствующая часть.
#   bin/rails runner script/translations/pl/link_continuations.rb [DRY_RUN=1]
require 'json'

LANG = 'la'
DRY = ENV['DRY_RUN'].present?

AUTHOR_IDS = ENV['AUTHORS'] ? ENV['AUTHORS'].split(',').map(&:to_i) : nil

def la_page_for(ru_page)
  ::Page.find_by(lang: LANG, group_lang_id: ru_page.group_lang_id)
end

def family_for(la_page)
  work = la_page.title.to_s
                  .sub(/,\s*(Liber|Libri|Tractatus|Epistolae|Sermo|Sermones)\b.*\z/, '')
                  .sub(/\s+\d+\s*[–-]\s*\d+\s*(?:\(\d+\s*\/\s*\d+\))?\z/, '')
                  .sub(/\s*\(\d+\s*\/\s*\d+\)\z/, '')
                  .strip
  return [] if work.blank?
  ::Page.where(lang: LANG, parent_id: la_page.parent_id, page_type: 1)
         .where("title LIKE ?", "#{work}%").order(:id).to_a
end

def link!(ru_page, la_page)
  holder = ::Page.find_by(lang: LANG, group_lang_id: ru_page.group_lang_id)
  return false if holder && holder.id != la_page.id
  return false if la_page.group_lang_id == ru_page.group_lang_id
  puts "#{ru_page.title}  →  #{la_page.title}"
  la_page.update_columns(group_lang_id: ru_page.group_lang_id) unless DRY
  true
end

ORDINALS = {
  'первая' => 1, 'вторая' => 2, 'третья' => 3, 'четвертая' => 4, 'четвёртая' => 4,
  'пятая' => 5, 'шестая' => 6, 'седьмая' => 7, 'восьмая' => 8, 'девятая' => 9,
  'десятая' => 10, 'одиннадцатая' => 11, 'двенадцатая' => 12, 'тринадцатая' => 13,
  'четырнадцатая' => 14, 'пятнадцатая' => 15, 'шестнадцатая' => 16, 'семнадцатая' => 17,
  'восемнадцатая' => 18, 'девятнадцатая' => 19, 'двадцатая' => 20,
  'двадцать первая' => 21, 'двадцать вторая' => 22, 'двадцать третья' => 23
}.freeze

# номер книги, с которой начинается русская страница (по «Книга одиннадцатая»)
def book_number(page)
  text = page.body.to_s.gsub(/<[^>]+>/, ' ')
  m = text.match(/Книга\s+(\d{1,2})\b/)
  return m[1].to_i if m
  m = text.match(/Книга\s+(двадцать\s+(?:первая|вторая|третья)|#{ORDINALS.keys.join('|')})/i)
  m ? ORDINALS[m[1].downcase] : nil
end

def numbers_of(title)
  t = title.to_s
  if (m = t.match(/Libri\s+(\d+)\s*[–-]\s*(\d+)/))
    (m[1].to_i..m[2].to_i)
  elsif (m = t.match(/Liber\s+(\d+)/))
    n = m[1].to_i
    (n..n)
  end
end

def range_of(title)
  m = title.to_s.match(/(\d+)\s*[–-]\s*(\d+)/)
  m ? (m[1].to_i..m[2].to_i) : nil
end

authors = AUTHOR_IDS ? ::Page.where(lang: 'ru', page_type: 4).where(id: AUTHOR_IDS) : ::Page.where(lang: 'ru', page_type: 4)
linked = 0
authors.each do |author|
  ru_pages = ::Page.where(lang: 'ru', parent_id: author.id, page_type: 1).order(:id).to_a
  puts "== #{author.title} (русских трудов: #{ru_pages.size})"
  ru_pages.each do |ru|
    next if la_page_for(ru)
    title = ru.title.to_s
    base = title.sub(/\s*#\d+\z/, '').strip
    idx = title[/#(\d+)/, 1].to_i
    idx = 1 if idx.zero?
    siblings = ru_pages.select { |p| p.title.to_s.sub(/\s*#\d+\z/, '').strip == base }
    linked_sibling = siblings.find { |p| la_page_for(p) }
    next unless linked_sibling
    la_start = la_page_for(linked_sibling)
    family = family_for(la_start)
    next if family.empty?

    book = book_number(ru)
    by_book = book ? family.find { |pp| (r = numbers_of(pp.title)) && r.cover?(book) } : nil
    target = by_book
    # отдельные письма: номер из названия («Письмо 215», «Письма (28, 29, 246, 210)»)
    if target.nil? && title.match?(/письм/i)
      rng = title.match(/(\d{1,3})\s*[–-]\s*(\d{1,3})/)
      num = if rng
              a, b = rng[1].to_i, rng[2].to_i
              idx > 1 ? (a + b) / 2 : a
            else
              title[/\b(\d{1,3})\b/, 1]&.to_i
            end
      target = family.find { |pp| (r = range_of(pp.title)) && r.cover?(num) } if num
    end
    unless target
      puts "  пропуск (нет ориентира): #{title}"
      next
    end
    if (holder = ::Page.find_by(lang: LANG, group_lang_id: target.group_lang_id)) && holder.id != target.id
      idx2 = family.index(target)
      target = family[idx2 + 1] || family.last
    end
    next unless target
    linked += 1 if link!(ru, target)
  end
end
puts "привязано страниц: #{linked}"
