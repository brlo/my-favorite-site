#!/usr/bin/env python3
"""Григорий Богослов: автор + «Ausgewählte Reden» (BKV)."""
import os
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402

DB = os.path.join(ROOT, 'db', 'translations', 'de')
TMP = os.path.join(ROOT, 'tmp', 'de_bkv')
AUTHOR = os.path.join(ROOT, 'script', 'translations', 'de', 'authors', 'gregor_nazianz.html')
SOURCE = (
    '<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Ausgewählte Reden</em> '
    '(Bibliothek der Kirchenväter). Text nach '
    '<a href="https://bkv.unifr.ch/de/works/cpg-3010/versions/reden-bkv">bkv.unifr.ch</a>; '
    'die Anmerkungen der Ausgabe sind weggelassen.</p>'
)


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def sections():
    with zipfile.ZipFile(os.path.join(TMP, 'naz_red.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for heading in doc.xpath('//h2'):
        title = ''.join(heading.itertext()).strip()
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        parts.append(f'<h2>{title}</h2>{body}')
    return ''.join(parts)


def main():
    author_html = open(AUTHOR, encoding='utf-8').read().strip()
    author = f'''# Григорий Богослов: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_nazianzen.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "uSyc_Григорий_Богослов_IV_век"
    path: "Gregor_von_Nazianz"
    title: "Gregor von Nazianz, 4. Jh."
    title_sub: "Heiliger (~329–390), Erzbischof von Konstantinopel, Kirchenvater und Kirchenlehrer, Theologe und Dichter"
    copy_cover: true
    menu: {{ parent: "4. Jahrhundert", title: "Gregor von Nazianz, Heiliger (~329–390)", replace: "Gregor von Nazianz, Heiliger (~329–390)", priority: 13 }}
    update: true
    body: |-
{block(author_html)}
'''
    works = f'''# Григорий Богослов: «Ausgewählte Reden» (немецкая библиотека)
# Сборка: script/translations/de/build_nazianzen.py

lang: de
list: "Gregor_von_Nazianz"
folders:
  - {{ path: "Reden", priority: 1 }}
pages:

  - src: "nBZM_Слова_изд_1912_г_1"
    path: "Gregor_Nazianz_Ausgewaehlte_Reden"
    title: "Ausgewählte Reden (Auswahl)"
    menu: {{ parent: "Reden", title: "Ausgewählte Reden (Auswahl)", priority: 1 }}
    update: true
    body: |-
{block('<p><em>Ausgewählte Reden (Bibliothek der Kirchenväter).</em></p>' + sections())}
    references: |-
{block(SOURCE)}
'''
    for name, text in (('naz_author.yml', author), ('naz_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
