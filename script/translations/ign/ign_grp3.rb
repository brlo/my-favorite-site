e=Page.find_by(lang:'en', path:'eusebius-the-church-history-3'); puts e.body.scan(/<h2[^>]*>([^<]*)<\/h2>/).flatten.join(',')
j=Page.find_by(lang:'ja', path:'聖使徒規則'); puts j.body[0,300]; puts j.body.scan(/39/).size; i=j.body.index('39'); puts j.body[i-100,300] if i
