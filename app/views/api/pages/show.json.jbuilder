pg = @page

json.success 'ok'

json.item do
  json.id                pg.id.to_s
  json.is_published      pg.is_published
  json.page_type         pg.page_type.to_s
  json.title             pg.title
  json.title_sub         pg.title_sub
  json.meta_desc         pg.meta_desc
  json.path              pg.path
  json.parent_id         pg.parent_id.to_s
  json.lang              pg.lang
  json.group_lang_id     pg.group_lang_id.to_s
  json.body              pg.body
  json.references        pg.references
  json.tags_str          pg.tags&.join(', ')
  json.priority          pg.priority
  json.created_at        pg.c_at
  json.updated_at        pg.u_at
end

  # [ items ]
json.menu pg.menu
