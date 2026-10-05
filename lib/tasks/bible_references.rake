namespace :bible_refs do
  desc 'Выставить is_past всем трудам (листьям с текстом) внутри списков святых отцов'
  task mark_past: :environment do
    level = ::Page.where(path_low: ::PAST_ROOT_PATHS).pluck(:id)
    ids = []
    while level.any?
      ids.concat(level)
      level = ::Page.where(parent_id: level).pluck(:id)
    end
    works = ::Page.where(id: ids, is_published: true).where.not(id: ::Page.where(parent_id: ids).select(:parent_id))
                  .where.not(body: [nil, ''])
    n = works.where(is_past: [nil, false]).update_all(is_past: true)
    puts "is_past выставлен у #{n} страниц (всего трудов: #{works.count})"
  end

  desc 'Пересобрать ссылки на Писание для всех страниц с is_past'
  task rebuild: :environment do
    ::BibleReference.where.not(page_id: ::Page.where(is_past: true).select(:id)).delete_all
    total = 0
    ::Page.where(is_past: true).find_each do |page|
      total += ::BibleCitationExtractor.call(page)
    end
    ::Rails.cache.delete_matched('bible_refs/*')
    puts "Найдено ссылок: #{total}"
  end
end
