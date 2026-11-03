#!/usr/bin/env python3
# Новый греко-латинский текст «Послания к Филиппийцам» для grc-страницы Επιστολή-Πολυκάρπου-προς-Φιλιππησίους:
# Lake (1912) в исправленной редакции Open Apostolic Fathers (CC BY-SA 4.0), файл tmp/pol/oaf/010-polycarp-philippians.txt:
#   curl -o tmp/pol/oaf/010-polycarp-philippians.txt https://raw.githubusercontent.com/jtauber/apostolic-fathers/master/texts/010-polycarp-philippians.txt
#   python3 tmp/pol/grc_phil.py -> tmp/pol/grc_phil_body.html, tmp/pol/grc_phil_refs.html
import html, re
from collections import OrderedDict
chs = OrderedDict()
for line in open('tmp/pol/oaf/010-polycarp-philippians.txt', encoding='utf-8'):
    m = re.match(r'(\d+)\.(\d+) (.+)', line.strip())
    ch, sec, text = int(m[1]), int(m[2]), m[3]
    chs.setdefault(ch, []).append(text if ch == 0 else f'{sec}. {text}')
body = ''.join(f'<h2>{ch}</h2>' + ''.join(f'<p>{html.escape(p, quote=False)}</p>' for p in ps) for ch, ps in chs.items())
refs = ('<p>Κείμενο: Kirsopp Lake, <em>The Apostolic Fathers</em>, τόμ. 1 (Loeb Classical Library), London 1912, '
        'κατά τη διορθωμένη έκδοση <a href="https://github.com/jtauber/apostolic-fathers">Open Apostolic Fathers</a> '
        '(J. Tauber, S. Macdonald, 2019, CC BY-SA 4.0). Τα κεφ. 10–12, 14 και το τέλος του 13 σώζονται μόνο σε αρχαία λατινική μετάφραση.</p>'
        '<p>https://el.wikisource.org/wiki/Επιστολή_Πολυκάρπου_προς_Φιλιππησίους</p>'
        '<p>http://khazarzar.skeptik.net/pgm/PG_Migne/Polycarpus%20Smyrnaeus_PG%2005/Epistula%20ad%20Philippenses.pdf</p>')
open('tmp/pol/grc_phil_body.html', 'w').write(body)
open('tmp/pol/grc_phil_refs.html', 'w').write(refs)
print(len(chs), 'chapters', len(body), 'chars')
