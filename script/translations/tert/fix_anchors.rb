# ссылки на главу 10 трактата: якорь изменился вместе с заголовком главы
new_anchor = 'HH-10-Покаяние-язычников-и-Пастырь'
Page.where(lang: 'ru', path: %w[тертуллиан иконы-почитают]).each do |q|
  body = q.body.gsub(%r{(wvx9_[^"#]*)#HH-10"}) { %(#{$1}##{new_anchor}") }
  next puts("без изменений: #{q.path}") if body == q.body
  q.update!(body: body)
  puts "обновлено: #{q.path} #{q.body_rendered.to_s.include?(new_anchor)}"
end
