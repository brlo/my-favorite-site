# Страница-список раздела «Библейские цитаты» на корейском + заполнение заготовки меню 1477 (и локально, и на проде)
ja = Page.find_by!(lang: 'ja', path_low: 'jp_q')
parent = Page.find_by!(lang: 'ko', path_low: 'links_ko')
pg = Page.find_by(lang: 'ko', path_low: 'ko-q') || Page.new(
  ja.attributes.except('id', 'created_at', 'updated_at', 'parent_id', 'lang', 'path', 'path_low', 'title', 'title_sub', 'body', 'redirect_from').compact
    .select { |k, _| Page.column_names.include?(k) },
)
pg.assign_attributes(lang: 'ko', path: 'ko-q', title: '성경 구절', title_sub: '정교회 교리를 변호하기 위한 성경 구절 모음', parent_id: parent.id,
                     group_lang_id: ja.group_lang_id, is_published: true, body: '<p>정교회 교리를 변호하기 위한 성경 구절 모음입니다.</p>')
pg.save!
Menu.find(1477).update!(path: 'ko-q')
puts "ok #{pg.id} #{pg.path}"
