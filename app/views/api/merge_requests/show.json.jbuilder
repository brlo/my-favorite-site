mr = @mr
pg = @page

json.success 'ok'

json.item do
  json.id              mr.id.to_s
  json.page_id         mr.page_id.to_s
  json.src_ver         mr.src_ver&.strftime("%Y-%m-%d %H:%M:%S")
  json.dst_ver         mr.dst_ver&.strftime("%Y-%m-%d %H:%M:%S")
  json.plus_i          mr.plus_i
  json.minus_i         mr.minus_i
  json.text_diffs      mr.text_diffs
  json.attrs_diff      mr.attrs_diff
  json.is_merged       mr.is_merged.to_i
  json.action_at       mr.action_at&.strftime("%Y-%m-%d %H:%M:%S")
  json.created_at      mr.created_at.strftime("%Y-%m-%d %H:%M:%S")
  json.updated_at      mr.updated_at.strftime("%Y-%m-%d %H:%M:%S")
  json.updated_at_word mr.updated_at_word
  json.user do |json|
    json.id       @user.id.to_s
    json.name     @user.name
    json.username @user.username
  end
  json.page do |json|
    json.id                pg.id.to_s
    json.is_published      pg.is_published
    json.merge_ver         pg.merge_ver&.strftime("%Y-%m-%d %H:%M:%S")
    json.page_type         pg.page_type.to_i
    json.title             pg.title
    json.title_sub         pg.title_sub
    json.meta_desc         pg.meta_desc
    json.path              pg.path
    json.parent_id         pg.parent_id.to_s
    json.lang              pg.lang
    json.group_lang_id     pg.group_lang_id.to_s

    json.body_as_arr       mr.src_ver == pg.merge_ver ? pg.body_as_arr : []

    json.body              pg.body
    json.references        pg.references
    json.tags_str          pg.tags&.join(', ')
    json.priority          pg.priority
    json.created_at        pg.c_at
    json.updated_at        pg.u_at
  end
end
