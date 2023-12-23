json.success 'ok'

json.items do
  json.array!(@pages) do |page|
    json.id              page.id.to_s
    json.title           page.title
    json.lang            page.lang
    json.created_at      page.c_at.strftime("%Y-%m-%d %H:%M:%S")
    json.updated_at      page.u_at.strftime("%Y-%m-%d %H:%M:%S")
    json.updated_at_word page.updated_at_word
  end
end
