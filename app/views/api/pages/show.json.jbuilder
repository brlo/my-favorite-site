pg = @page

json.success 'ok'

json.item do
  json.id                pg.id.to_s
  json.published         pg.published
  json.page_type         pg.page_type
  json.title             pg.title
  json.title_sub         pg.title_sub
  json.meta_desc         pg.meta_desc
  json.path              pg.path
  json.path_parent       pg.path_parent
  json.path_parent_title pg.path_parent_title
  json.path_next         pg.path_next
  json.path_next_title   pg.path_next_title
  json.path_prev         pg.path_prev
  json.path_prev_title   pg.path_prev_title
  json.lang              pg.lang
  json.group_lang_id     pg.group_lang_id
  json.body              pg.body
  json.references        pg.references
  json.tags_str          pg.tags&.join(', ')
  json.priority          pg.priority
  json.created_at        pg.c_at
  json.updated_at        pg.u_at
end

json.tree_menu do
  # [ {obj: _, childs: []}, ... ]
  json.items pg.tree_menu
end
