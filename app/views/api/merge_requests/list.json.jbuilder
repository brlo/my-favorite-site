json.success 'ok'

json.items do
  json.array!(@mrs) do |mr|
    page = @pages_by_id[mr.page_id]

    json.id                mr.id.to_s
    json.page_id           mr.page_id.to_s
    json.page_title        page.title
    json.minus_i           mr.minus_i
    json.plus_i            mr.plus_i
    json.is_merged         mr.is_merged.to_i
    json.action_at         mr.action_at&.strftime("%Y-%m-%d %H:%M:%S")
    json.created_at        mr.created_at.strftime("%Y-%m-%d %H:%M:%S")
    json.updated_at        mr.updated_at.strftime("%Y-%m-%d %H:%M:%S")
    json.updated_at_word   mr.updated_at_word
    json.author do |json|
      json.name mr.user&.name
    end
  end
end
