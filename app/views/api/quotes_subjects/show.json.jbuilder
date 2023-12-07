
json.success 'ok'

json.item do
  json.partial! "api/quotes_subjects/quotes_subject", quotes_subject: @quotes_subject
end
