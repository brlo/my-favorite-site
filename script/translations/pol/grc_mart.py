#!/usr/bin/env python3
# Новый греческий текст «Мученичества Поликарпа» для grc-страницы Μαρτύριο_του_Αγίου_Πολυκάρπου_Επισκόπου_Σμύρνης:
# Lake (1912) в исправленной редакции Open Apostolic Fathers (CC BY-SA 4.0), файл tmp/pol/oaf/014-martyrdom.txt:
#   curl -o tmp/pol/oaf/014-martyrdom.txt https://raw.githubusercontent.com/jtauber/apostolic-fathers/master/texts/014-martyrdom.txt
#   python3 tmp/pol/grc_mart.py -> tmp/pol/grc_mart_body.html, tmp/pol/grc_mart_refs.html
import html, re
from collections import OrderedDict
chs = OrderedDict()
for line in open('tmp/pol/oaf/014-martyrdom.txt', encoding='utf-8'):
    m = re.match(r'(EP|\d+)\.(\d+) (.+)', line.strip())
    ch, sec, text = m[1], int(m[2]), m[3]
    if ch == 'EP' and sec == 0:
        chs['EP'] = [('title', text.capitalize().replace('mosquiensi', 'Mosquiensi'))]
        continue
    chs.setdefault(ch, []).append(text if ch == '0' else f'{sec}. {text}')
body = ''
for ch, ps in chs.items():
    if ch == 'EP':
        body += f'<h2>{ps[0][1]}</h2>'
        ps = ps[1:]
    else:
        body += f'<h2>{ch}</h2>'
    body += ''.join(f'<p>{html.escape(p, quote=False)}</p>' for p in ps)
refs = ('<p>Κείμενο: Kirsopp Lake, <em>The Apostolic Fathers</em>, τόμ. 2 (Loeb Classical Library), London 1913, '
        'κατά τη διορθωμένη έκδοση <a href="https://github.com/jtauber/apostolic-fathers">Open Apostolic Fathers</a> '
        '(J. Tauber, S. Macdonald, 2019, CC BY-SA 4.0).</p>'
        '<p>https://www.loebclassics.com/view/martyrdom_polycarp/2003/pb_LCL024.367.xml</p>'
        '<p>https://christianvivliografia.wordpress.com/2011/02/23/μαρτύριον-τοῦ-ἁγ-πολυκάρπου-αἶρε-το/</p>')
open('tmp/pol/grc_mart_body.html', 'w').write(body)
open('tmp/pol/grc_mart_refs.html', 'w').write(refs)
print(len(chs), 'chapters', len(body), 'chars', list(chs)[-3:])
