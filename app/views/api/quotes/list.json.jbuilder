json.success 'ok'

json.items do
  json.array!(@quotes_pages) do |page|
    json.id       page.id.to_s
    json.title    page.title
    json.position page.position
    json.lang     page.lang
  end
end
