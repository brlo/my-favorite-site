pg = @page

json.success 'ok'

json.item do
  json.id                pg.id.to_s
  json.is_bibleox        pg.is_bibleox
  json.is_menu_icons     pg.is_menu_icons
  json.is_published      pg.is_published
  json.is_deleted        pg.is_deleted
  json.is_search         pg.is_search
  json.is_show_parent    pg.is_show_parent
  json.page_type         pg.page_type.to_i
  json.edit_mode         pg.edit_mode.to_i
  json.title             pg.title
  json.title_sub         pg.title_sub
  json.meta_desc         pg.meta_desc
  json.path              pg.path
  json.parent_id         pg.parent_id.to_s
  json.lang              pg.lang
  json.group_lang_id     pg.group_lang_id.to_s
  json.links             pg.links.to_a
  json.body              pg.body
  json.references        pg.references
  json.tags_str          pg.tags&.join(', ')
  json.priority          pg.priority
  json.audio             pg.audio
  json.cover             pg.cover.urls
  json.is_pdf            pg.pdf_exists?
  json.created_at        pg.c_at
  json.updated_at        pg.u_at
end

  # [ items ]
json.menu pg.menu
