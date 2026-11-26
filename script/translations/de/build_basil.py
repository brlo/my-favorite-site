#!/usr/bin/env python3
"""Сборка немецкого Василия Великого: автор + «Hexaemeron» (BKV 1925)."""
import os
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
DB = os.path.join(ROOT, 'db', 'translations', 'de')
OUT = os.path.join(ROOT, 'tmp', 'de_bkv', 'out')
AUTHOR = os.path.join(ROOT, 'script', 'translations', 'de', 'authors', 'basilius.html')
SOURCE = (
    '<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, '
    '<em>Homilien über das Hexaemeron</em> (Bibliothek der Kirchenväter, 1. Reihe, Bd. 47), '
    'Kempten/München 1925. Text nach '
    '<a href="https://bkv.unifr.ch/de/works/cpg-2835/versions/homilien-uber-das-hexaemeron-bkv">bkv.unifr.ch</a>; '
    'die Anmerkungen der Ausgabe sind weggelassen.</p>'
)


sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402

ORDINALS = {'Erste': 1, 'Zweite': 2, 'Dritte': 3, 'Vierte': 4, 'Fünfte': 5,
            'Sechste': 6, 'Siebte': 7, 'Achte': 8, 'Neunte': 9}


def sections():
    with zipfile.ZipFile(os.path.join(ROOT, 'tmp', 'de_bkv', 'bas_hex.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for heading in doc.xpath('//h2'):
        title = ''.join(heading.itertext()).strip()
        number = next((v for k, v in ORDINALS.items() if title.startswith(k)), 0)
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        parts.append(f'<h2>{number}</h2>{body}')
    return ''.join(parts)


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def main():
    body = ('<p><em>Homilien über das Hexaemeron, übersetzt von der BKV-Ausgabe '
            '(Bibliothek der Kirchenväter, 1. Reihe, Bd. 47, Kempten/München 1925).</em></p>'
            + sections())
    author_html = open(AUTHOR, encoding='utf-8').read().strip()
    author = f'''# Василий Великий: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_basil.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "mz9h_Василий_Великий_IV_век"
    path: "Basilius_der_Große"
    title: "Basilius der Große, 4. Jh."
    title_sub: "Heiliger (~329–379), Erzbischof von Cäsarea in Kappadokien, Kirchenvater und Kirchenlehrer"
    copy_cover: true
    menu: {{ parent: "4. Jahrhundert", title: "Basilius der Große, Heiliger (~329–379)", replace: "Basilius der Große, Heiliger (~329–379)", priority: 3 }}
    update: true
    body: |-
{block(author_html)}
'''
    works = f'''# Василий Великий: «Hexaemeron» (немецкая библиотека)
# Сборка: script/translations/de/build_basil.py

lang: de
list: "Basilius_der_Große"
folders:
  - {{ path: "Werke", priority: 1 }}
pages:

  - src: "CP8V_Беседы_на_Шестоднев"
    path: "Basilius_Hexaemeron"
    title: "Homilien über das Hexaemeron"
    menu: {{ parent: "Werke", title: "Homilien über das Hexaemeron", priority: 1 }}
    update: true
    body: |-
{block(body)}
    references: |-
{block(SOURCE)}
'''
    for name, text in (('basil_author.yml', author), ('basil_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
