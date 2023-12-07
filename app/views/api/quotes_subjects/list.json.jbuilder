json.success 'ok'

json.items do
  json.array! @quotes_subjects, partial: "api/quotes_subjects/quotes_subject", as: :quotes_subject
end
