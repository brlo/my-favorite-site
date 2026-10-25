namespace :bible do
  # Перевод Библии из модуля MyBible (https://www.ph4.ru/b4_my.php):
  #   bin/rails bible:import_mybible FILE=tmp/bibles/HIND.SQLite3 TR=hi-ov [REPLACE=1] [FIX='침례=세례']
  # Код перевода (TR) должен быть заведён в BIB_LANG_TO_LOCALE (оттуда же язык стихов) и в локалях.
  desc "Import a Bible translation from a MyBible SQLite module"
  task :import_mybible => :environment do
    tr_code = ENV.fetch('TR')
    raise "перевода #{tr_code} нет в BIB_LANG_TO_LOCALE" unless ::BIB_LANG_TO_LOCALE.key?(tr_code)

    fixes = ENV['FIX'].to_s.split(',').to_h { _1.split('=', 2) }
    result = ::MybibleImporter.call(ENV.fetch('FILE'), tr_code: tr_code, lang: ::BIB_LANG_TO_LOCALE[tr_code], is_replace: ENV['REPLACE'] == '1', fixes: fixes)
    ::Rails.cache.delete('offline:tr_codes')
    puts result.inspect
  end

  # Ссылки статей на старый перевод -> на новый: bin/rails bible:relink FROM=cn-ccbs TO=cn-sb
  desc "Point article links from one Bible translation to another"
  task :relink => :environment do
    from, to = "/#{ENV.fetch('FROM')}/", "/#{ENV.fetch('TO')}/"
    ::Page.where('body LIKE :q OR "references" LIKE :q', q: "%#{from}%").find_each do |page|
      page.update!(body: page.body.to_s.gsub(from, to), references: page.references.to_s.gsub(from, to))
      puts "#{page.lang}:#{page.path}"
    end
  end

  # Удалить стихи перевода, которых нет в модуле MyBible (лишние номера, чужие книги):
  #   bin/rails bible:prune FILE=tmp/bibles/SCH51.SQLite3 TR=ge-sch [DRY_RUN=1]
  desc "Delete verses of a translation that are absent from a MyBible module"
  task :prune => :environment do
    db = ::SQLite3::Database.new(ENV.fetch('FILE'), readonly: true)
    addresses = db.execute('SELECT book_number, chapter, verse FROM verses').to_set do |b, c, v|
      "#{::MybibleImporter::BOOK_BY_ID[b.to_i]}:#{c.to_i}:#{v.to_i}"
    end
    extra = ::Verse.where(tr_code: ENV.fetch('TR')).pluck(:id, :address).reject { |_, a| addresses.include?(a) }
    puts extra.map(&:last).group_by { _1.split(':').first }.transform_values(&:size).inspect
    ::Verse.where(id: extra.map(&:first)).delete_all unless ENV['DRY_RUN'] == '1'
    ::Rails.cache.delete('offline:tr_codes')
    puts "#{ENV['DRY_RUN'] == '1' ? 'would delete' : 'deleted'}: #{extra.size}"
  end

  # Удалить перевод целиком: bin/rails bible:delete TR=cn-ccbs
  desc "Delete all verses of a Bible translation"
  task :delete => :environment do
    puts ::Verse.where(tr_code: ENV.fetch('TR')).delete_all
    ::Rails.cache.delete('offline:tr_codes')
  end
end
