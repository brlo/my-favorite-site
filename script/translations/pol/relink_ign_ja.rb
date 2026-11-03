# Японская страница Игнатия ссылалась на английский текст «Послания к Филиппийцам» Поликарпа:
# после загрузки японского перевода (db/translations/ja/pol_01_works.yml) ведём ссылку на него.
#   bin/rails runner script/translations/pol/relink_ign_ja.rb [DRY_RUN=1]
OLD = '<a href="https://bibleox.com/ja/en/w/Plk_Ph#HH-13">ポリュカルポス『フィリピの信徒への手紙』13章（英語）</a>'
NEW = '<a href="https://bibleox.com/ja/ja/w/Pk1F_フィリピの教会への手紙#HH-13">ポリュカルポス『フィリピの教会への手紙』13章</a>'

abort 'нет японского перевода Послания к Филиппийцам' unless Page.exists?(lang: 'ja', path: 'Pk1F_フィリピの教会への手紙')
page = Page.find_by!(lang: 'ja', path: 'mlNq_アンティオキアのイグナティオス1世紀')
count = page.body.scan(OLD).size
puts "#{page.path}: замен #{count}"
page.update!(body: page.body.gsub(OLD, NEW)) if count.positive? && ENV['DRY_RUN'].blank?
