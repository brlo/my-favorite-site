json.success 'ok'

pv = @page_visits || {}

json.items do
  json.array!(@pages) do |page|
    title = page.title
    p_title = @parent_pages[page.parent_id]
    title = "#{title} ⬅︎ #{p_title}" if p_title

    json.id              page.id
    json.title           title
    json.path            page.path
    json.is_published    page.is_published
    json.is_deleted      page.is_deleted
    json.page_type       page.page_type.to_i
    json.edit_mode       page.edit_mode.to_i
    json.group_lang_id   page.group_lang_id.to_s
    json.parent_id       page.parent_id
    # json.parent_title do |json|
    #   @parent_pages[page.parent_id.to_s]
    # end
    # json.author do |json|
    #   json.name page.user&.name
    # end
    json.lang            page.lang
    json.created_at      page.created_at.strftime("%Y-%m-%d %H:%M:%S")
    json.updated_at      page.updated_at.strftime("%Y-%m-%d %H:%M:%S")
    json.updated_at_word page.updated_at_word
    json.visits          pv[page.id].to_i
  end
end
