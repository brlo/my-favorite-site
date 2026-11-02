p=Page.find_by(lang:'grc', path:'Επιστολή-Πολυκάρπου-προς-Φιλιππησίους'); puts p.body.scan(/<h2[^>]*>([^<]*)<\/h2>/).flatten.join(','); i=p.body.index('Ἐγράψατέ'); puts p.body[i-200,600] if i
j=Page.find_by(lang:'ja', path:'聖使徒規則'); puts j.body.scan(/<h[23][^>]*>([^<]*)<\/h[23]>/).flatten.first(50).join(' | ')
e=Page.find_by(lang:'en', path:'Plk_Ph'); puts e.body.scan(/<h2[^>]*>([^<]*)<\/h2>/).flatten.join(',')
