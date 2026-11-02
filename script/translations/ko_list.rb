# Страница-список раздела «Библейские цитаты» на корейском + заполнение заготовки меню 1477 (и локально, и на проде)
ja = Page.find_by!(lang: 'ja', path_low: 'jp_q')
parent = Page.find_by!(lang: 'ko', path_low: 'links_ko')
pg = Page.find_by(lang: 'ko', path_low: 'ko-q') || Page.new(
  ja.attributes.except('id', 'created_at', 'updated_at', 'parent_id', 'lang', 'path', 'path_low', 'title', 'title_sub', 'body', 'redirect_from').compact
    .select { |k, _| Page.column_names.include?(k) },
)
pg.assign_attributes(lang: 'ko', path: 'ko-q', title: '성경 구절', title_sub: '정교회 교리를 변호하기 위한 성경 구절 모음', parent_id: parent.id,
                     group_lang_id: ja.group_lang_id, is_published: true, body: '<p>정교회 교리를 변호하기 위한 성경 구절 모음입니다.</p><p><strong>본문을 보충하거나 고치려는 분들을 위한 안내</strong></p><ol><li><p><strong>주제를 흐리지 말 것</strong>. 덧붙이려는 구절이 글의 주제와 직접 관련이 없다면 따로 글을 만드는 것이 낫습니다.</p></li><li><p><strong>치우치지 않으려 애쓸 것</strong>. 자기 생각을 비판적으로 살피며, 그 구절이 고른 주제에 정말로 맞는지 따져 보아야 합니다.</p></li><li><p><strong>구절을 문맥과 맞추어 볼 것</strong>. 본문은 그것을 가져온 문맥에 맞게 써야 합니다. 예외는 짧게 설명해야 합니다.</p></li><li><p><strong>짧게 쓸 것</strong>. 구절은 많이, 자기 설명은 적게 합니다. 달리 할 수 없는 예외적인 경우만 빼고 그렇습니다.</p></li></ol>')
pg.save!
Menu.find(1477).update!(path: 'ko-q')
puts "ok #{pg.id} #{pg.path}"
