#!/usr/bin/env python3
"""Сборка немецкого Иоанна Дамаскина: автор + «Точное изложение» в 4 книгах."""
import os
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402

DB = os.path.join(ROOT, 'db', 'translations', 'de')
TMP = os.path.join(ROOT, 'tmp', 'de_bkv')
AUTHOR = os.path.join(ROOT, 'script', 'translations', 'de', 'authors', 'damascene.html')
SOURCE = (
    '<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Genaue Darlegung des '
    'orthodoxen Glaubens</em> (Bibliothek der Kirchenväter). Text nach '
    '<a href="https://bkv.unifr.ch/de/works/cpg-8043/versions/genaue-darlegung-des-orthodoxen-glaubens-bkv">'
    'bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>'
)


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def book_parts():
    with zipfile.ZipFile(os.path.join(TMP, 'dam_exp.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for i, book in enumerate(doc.xpath('//h2'), 1):
        body = [f'<h2>Buch {i}</h2>']
        for chapter in book.getparent().xpath('.//h3'):
            title = ''.join(chapter.itertext()).strip()
            text = ''.join(be.para_html(p) for p in chapter.getparent().xpath('.//p'))
            body.append(f'<h3>{title}</h3>{text}')
        parts.append(''.join(body))
    return parts


def main():
    author_html = open(AUTHOR, encoding='utf-8').read().strip()
    books = book_parts()
    author = f'''# Иоанн Дамаскин: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_damascene.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "aOY9_Иоанн_Дамаскин_VIIVIII_вв"
    path: "Johannes_von_Damaskus"
    title: "Johannes von Damaskus, 8. Jh."
    title_sub: "Heiliger (~675–749), Kirchenvater und Kirchenlehrer, Theologe, Hymnendichter und Verteidiger der Ikonenverehrung"
    copy_cover: true
    menu: {{ parent: "8. Jahrhundert", title: "Johannes von Damaskus, Heiliger (~675–749)", replace: "Johannes von Damaskus, Heiliger (~675–749)", priority: 1 }}
    update: true
    body: |-
{block(author_html)}
'''
    works = f'''# Иоанн Дамаскин: труд (немецкая библиотека)
# Сборка: script/translations/de/build_damascene.py

lang: de
list: "Johannes_von_Damaskus"
folders:
  - {{ path: "Dogmatische Werke", priority: 1 }}
pages:

'''
    sources = [
        ('2SYs_Точное_изложение_православной_веры__книга_1', 'Johannes_Damaskus_Expositio_1', 'Genaue Darlegung des orthodoxen Glaubens — Buch 1'),
        ('71dN_Точное_изложение_православной_веры__книга_2', 'Johannes_Damaskus_Expositio_2', 'Genaue Darlegung des orthodoxen Glaubens — Buch 2'),
        ('zO0i_Точное_изложение_православной_веры__книга_3', 'Johannes_Damaskus_Expositio_3', 'Genaue Darlegung des orthodoxen Glaubens — Buch 3'),
        ('EfeP_Точное_изложение_православной_веры__книга_4', 'Johannes_Damaskus_Expositio_4', 'Genaue Darlegung des orthodoxen Glaubens — Buch 4'),
    ]
    for i, (src, path, title) in enumerate(sources):
        body = f'<p><em>{title} (Bibliothek der Kirchenväter).</em></p>' + books[i]
        works += f'''  - src: "{src}"
    path: "{path}"
    title: "{title}"
    menu: {{ parent: "Dogmatische Werke", title: "{title}", priority: {i + 1} }}
    update: true
    body: |-
{block(body)}
    references: |-
{block(SOURCE)}
'''
    for name, text in (('dam_author.yml', author), ('dam_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
