pg = @quotes_page

json.success 'ok'

json.item do
  json.id         pg.id.to_s
  json.s_id       pg.s_id
  json.path       pg.path
  json.title      pg.title
  json.meta_desc  pg.meta_desc
  json.position   pg.position
  json.lang       pg.lang
  json.body       pg.body
  json.created_at pg.c_at
end
