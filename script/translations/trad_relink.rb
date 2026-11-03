# Ссылки на русские страницы в переводах статей «Предания»: ведём на перевод того же языка, если он есть,
# иначе оставляем и помечаем язык. bin/rails runner script/translations/trad_relink.rb [APPLY]
SRC = %w[библейские_манускрипты древние-иконы Древние_христианские_храмы KPgB_Христианские_захоронения_и_надписи 2NCD_Постная_кухня
         bdRJ_Разные_древние_образы_не_вошедшие_в_основную_коллекцию]
MARK = { 'en' => ' (in Russian)', 'ja' => '（ロシア語）', 'ko' => '(러시아어)', 'de' => ' (auf Russisch)', 'zh-Hans' => '（俄语）', 'el' => ' (στα ρωσικά)' }
MARKED = /\A[\s,、，]*[(（]?\s*(in Russian|ロシア語|러시아어|auf Russisch|俄语|στα ρωσικά)/
apply = ARGV.include?('APPLY')
SRC.each do |sp|
  ru = Page.find_by!(lang: 'ru', path: sp)
  Page.where(group_lang_id: ru.group_lang_id).where.not(lang: 'ru').each do |pg|
    changed = false
    fix = lambda do |html|
      html.to_s.gsub(%r{<a href="https://bibleox\.com/ru/ru/w/([^"#]+?)/?(#[^"]*)?"([^>]*)>(.*?)</a>(.{0,20})}m) do
        path, inner, after = URI.decode_www_form_component(Regexp.last_match(1)), Regexp.last_match(4), Regexp.last_match(5)
        whole = Regexp.last_match(0)
        target = (r = Page.find_by(lang: 'ru', path: path)) && r.group_lang_id.present? && Page.find_by(lang: pg.lang, group_lang_id: r.group_lang_id, is_published: true)
        changed = true
        if target
          # перевод появился: ссылку ведём на него, прежнюю пометку языка убираем
          %(<a href="https://bibleox.com/#{pg.lang}/#{pg.lang}/w/#{target.path}">#{inner}</a>#{after.sub(/\A\s*[(（](?:in Russian|ロシア語|러시아어|auf Russisch|俄语|στα ρωσικά)[)）]/, '')})
        elsif after =~ MARKED then (changed = false; whole)
        else %(#{whole[0, whole.length - after.length]}#{MARK[pg.lang]}#{after})
        end
      end
    end
    body, refs = fix.(pg.body), fix.(pg.references)
    next unless body != pg.body || refs != pg.references
    puts "#{pg.lang}:#{pg.path}"
    pg.update!(body: body, references: refs) if apply
  end
end
