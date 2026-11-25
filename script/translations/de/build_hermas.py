#!/usr/bin/env python3
"""Сборка немецкого «Пастыря Ерма» (BKV 1918)."""
import os
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402

DB = os.path.join(ROOT, 'db', 'translations', 'de')
EPUB = os.path.join(ROOT, 'tmp', 'de_bkv', 'herm.epub')

SOURCE = (
    '<hr><p><strong>Quelle:</strong> Übersetzung von Franz Zeller, '
    '<em>Der Hirte des Hermas</em> (Bibliothek der Kirchenväter, 1. Reihe, Bd. 35), '
    'München 1918. Text nach '
    '<a href="https://bkv.unifr.ch/de/works/cpg-1052/versions/der-hirte-des-hermas-bkv">bkv.unifr.ch</a>; '
    'die Anmerkungen der Ausgabe sind weggelassen.</p>'
)


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def work_body():
    with zipfile.ZipFile(EPUB) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = ['<p><em>Der Hirte des Hermas, übersetzt von Franz Zeller '
             '(Bibliothek der Kirchenväter, 1. Reihe, Bd. 35, München 1918).</em></p>']
    for heading in doc.xpath('//h3'):
        title = ''.join(heading.itertext()).strip().rstrip('.')
        section = heading.getparent()
        paragraphs = ''.join(be.para_html(p) for p in section.xpath('.//p'))
        parts.append(f'<h2>{title}</h2>{paragraphs}')
    return ''.join(parts)


def main():
    work = work_body() + SOURCE
    works = f'''# Пастырь Ерма (немецкая библиотека)
# Сборка: script/translations/de/build_hermas.py
# Меню после импорта переносит script/translations/de/unknown_authors_menu.rb.

lang: de
list: "Kirchenvaeter"
pages:

  - src: "Пастырь_Ерма"
    path: "Hirte_des_Hermas"
    title: "Hirte des Hermas"
    menu: {{ title: "Hirte des Hermas", priority: 10 }}
    update: true
    body: |-
{block(work)}
'''
    path = os.path.join(DB, 'herm_works.yml')
    open(path, 'w', encoding='utf-8').write(works)
    print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
