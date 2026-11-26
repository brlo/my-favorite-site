#!/usr/bin/env python3
"""Евсевий: «Мученики Палестины» (BKV, EN-оригинал)."""
import os
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402

TMP = os.path.join(ROOT, 'tmp', 'de_bkv')
OUT = os.path.join(ROOT, 'db', 'translations', 'de', 'eus_martyrs.yml')


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def sections():
    with zipfile.ZipFile(os.path.join(TMP, 'eus_mart.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for i, heading in enumerate(doc.xpath('//h2'), 1):
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        parts.append(f'<h2>{i}</h2>{body}')
    return ''.join(parts)


def main():
    body = ('<p><em>Die Märtyrer in Palästina (Bibliothek der Kirchenväter).</em></p>' + sections())
    text = f'''# Евсевий: «Мученики Палестины»
lang: de
src_lang: "en"
list: "Eusebius_von_Cäsarea"
folders:
  - {{ path: "Märtyrer", priority: 2 }}
pages:

  - src: "eusebius-the-church-history-9"
    path: "Eusebius_Maertyrer_Palaestinas"
    title: "Die Märtyrer in Palästina"
    menu: {{ parent: "Märtyrer", title: "Die Märtyrer in Palästina", priority: 1 }}
    update: true
    body: |-
{block(body)}
    references: |-
{block('<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Die Märtyrer in Palästina</em>. Text nach <a href="https://bkv.unifr.ch/de/works/cpg-3490/versions/uber-die-martyrer-in-palastina-bkv">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')}
'''
    open(OUT, 'w', encoding='utf-8').write(text)
    print('написан', OUT, os.path.getsize(OUT), 'байт')


if __name__ == '__main__':
    main()
