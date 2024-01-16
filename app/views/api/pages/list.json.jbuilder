json.success 'ok'

json.items do
  json.array!(@pages) do |page|
    json.id              page.id.to_s
    json.title           page.title
    json.is_published    page.is_published
    json.page_type       page.page_type.to_s
    json.group_lang_id   page.group_lang_id.to_s
    json.parent_id       page.parent_id.to_s
    json.author do |json|
      json.name page.user&.name
    end
    json.lang            page.lang
    json.created_at      page.c_at.strftime("%Y-%m-%d %H:%M:%S")
    json.updated_at      page.u_at.strftime("%Y-%m-%d %H:%M:%S")
    json.updated_at_word page.updated_at_word
  end
end
