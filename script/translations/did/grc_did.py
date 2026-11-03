#!/usr/bin/env python3
# Новый греческий текст «Дидахе» для grc-страницы ΔΙΔΑΧΗ: Lake (1912) в исправленной редакции
# Open Apostolic Fathers (CC BY-SA 4.0), файл tmp/pol/oaf/011-didache.txt:
#   curl -o tmp/pol/oaf/011-didache.txt https://raw.githubusercontent.com/jtauber/apostolic-fathers/master/texts/011-didache.txt
#   python3 script/translations/did/grc_did.py -> tmp/did/grc_did_body.html, tmp/did/grc_did_refs.html
# Заглавие (0.1) остаётся в подзаголовке страницы, в тексте главы 1–16, разделы с номерами, как было.
import html, re
from collections import OrderedDict
chs = OrderedDict()
for line in open('tmp/pol/oaf/011-didache.txt', encoding='utf-8'):
    m = re.match(r'(\d+)\.(\d+) (.+)', line.strip())
    ch, sec, text = int(m[1]), int(m[2]), m[3]
    if ch:
        chs.setdefault(ch, []).append(f'{sec} {text}')
body = ''.join(f'<h2>{ch}</h2>' + ''.join(f'<p>{html.escape(p, quote=False)}</p>' for p in ps) for ch, ps in chs.items())
refs = ('<p>Κείμενο: Kirsopp Lake, <em>The Apostolic Fathers</em>, τόμ. 1 (Loeb Classical Library), London 1912, '
        'κατά τη διορθωμένη έκδοση <a href="https://github.com/jtauber/apostolic-fathers">Open Apostolic Fathers</a> '
        '(J. Tauber, S. Macdonald, 2019, CC BY-SA 4.0). Χειρόγραφο: Ιεροσολυμιτικός κώδιξ 54 (1056).</p>'
        '<p><a href="https://el.wikisource.org/wiki/%CE%94%CE%B9%CE%B4%CE%B1%CF%87%CE%AE_%CF%84%CF%89%CE%BD_%CE%94%CF%8E%CE%B4%CE%B5%CE%BA%CE%B1_%CE%91%CF%80%CE%BF%CF%83%CF%84%CF%8C%CE%BB%CF%89%CE%BD">https://el.wikisource.org/wiki/Διδαχή_των_Δώδεκα_Αποστόλων</a></p>')
open('tmp/did/grc_did_body.html', 'w').write(body)
open('tmp/did/grc_did_refs.html', 'w').write(refs)
print(len(chs), 'chapters', len(body), 'chars')
