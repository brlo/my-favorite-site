json.extract! quotes_page, :id, :title, :lang, :body, :s_id, :created_at, :updated_at
json.url quotes_page_url(quotes_page, format: :json)
