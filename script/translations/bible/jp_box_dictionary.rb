# Публикует статьи-словари jp-box (ru и ja) из файлов в репозитории.
#
#   bin/rails runner script/translations/bible/jp_box_dictionary.rb
#
# Источники:
#   db/translations/bible/jp-box/dictionary_ru.html — русская статья
#   db/translations/bible/jp-box/dictionary_ja.html — японская статья
# Страницы ищутся по path_low; если их нет — создаются в разделе, где лежит
# соответствующая статья «О переводе» (тот же parent_id).

SRC_DIR = Rails.root.join('db/translations/bible/jp-box')

def publish(lang:, path:, title:, meta_desc:, src:, about_path:)
  body = File.read(src)
  page = ::Page.find_by(lang: lang, path_low: path.downcase)
  atoms = { title: title, meta_desc: meta_desc, body: body, page_type: 1, edit_mode: 1,
            is_published: true, is_bibleox: true }
  if page
    page.update!(atoms)
    puts "обновлено: ##{page.id} #{page.path} (#{page.body.length} знаков)"
  else
    about = ::Page.find_by(lang: lang, path_low: about_path.downcase)
    page = ::Page.create!(atoms.merge(
      lang: lang, path: path, parent_id: about&.parent_id, user_id: 1,
      group_lang_id: SecureRandom.hex(12)
    ))
    puts "создано: ##{page.id} #{page.path} (#{page.body.length} знаков)"
  end
end

publish(
  lang: 'ru', path: 'Словарь_японского_перевода_Библии',
  title: 'Словарь японского перевода Библии',
  meta_desc: 'Словарь терминов японского перевода Библии jp-box: греческое слово, ' \
             'японское написание, объяснение и пример из перевода.',
  src: SRC_DIR.join('dictionary_ru.html'),
  about_path: 'О_переводе_японской_Библии'
)

publish(
  lang: 'ja', path: 'ビブレオックス訳_用語集',
  title: 'ビブレオックス訳 用語集',
  meta_desc: 'ビブレオックス訳（jp-box）の用語集：ギリシア語、日本語表記、説明、本文の例。',
  src: SRC_DIR.join('dictionary_ja.html'),
  about_path: 'ビブレオックス訳について'
)
