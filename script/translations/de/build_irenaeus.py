#!/usr/bin/env python3
"""Сборка немецкого Иринея Лионского: автор + 5 книг «Против ересей» + «Erweis»."""
import os
import re
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402

DB = os.path.join(ROOT, 'db', 'translations', 'de')
TMP = os.path.join(ROOT, 'tmp', 'de_bkv')
AUTHOR = os.path.join(ROOT, 'script', 'translations', 'de', 'authors', 'irenaeus.html')

CONTRA_URL = 'https://bkv.unifr.ch/de/works/cpg-1306/versions/gegen-die-haeresien-bkv'
DEM_URL = 'https://bkv.unifr.ch/de/works/cpg-1307/versions/erweis-der-apostolischen-verkundigung-bkv'


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def load_doc(key):
    with zipfile.ZipFile(os.path.join(TMP, key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    return doc


def paragraphs(container):
    return ''.join(be.para_html(p) for p in container.xpath('.//p'))


def contra_books():
    doc = load_doc('iren_haer')
    books = [s for s in doc.xpath('//section') if s.get('class') == 'level2']
    result = []
    for book in books:
        h2 = book.find('h2')
        title = ''.join(h2.itertext()).strip() if h2 is not None else ''
        preface = []
        chapters = []
        for ch in book.xpath('./section'):
            h3 = ch.find('h3')
            number = be.chapter_number(h3) if h3 is not None else None
            body = paragraphs(ch)
            if not body:
                continue
            if number is None:
                preface.append(body)
            else:
                chapters.append((number, body))
        chapters.sort(key=lambda x: x[0])
        result.append((title, preface, chapters))
    return result


def demonstratio():
    doc = load_doc('iren_dem')
    return paragraphs(doc)


def source(kind, book=None):
    if kind == 'contra':
        label = f'Gegen die Häresien, Buch {book}'
        return (f'<p><strong>Quelle:</strong> Übersetzung von E. Klebba, '
                f'<em>{label}</em> (Bibliothek der Kirchenväter, 1. Reihe, Bd. 3–4), '
                f'München 1912. Text nach <a href="{CONTRA_URL}">bkv.unifr.ch</a>; '
                f'die Anmerkungen der Ausgabe sind weggelassen.</p>')
    return (f'<p><strong>Quelle:</strong> Übersetzung von E. Klebba, '
            f'<em>Erweis der apostolischen Verkündigung</em> (Bibliothek der Kirchenväter, '
            f'1. Reihe, Bd. 4), München 1912. Text nach '
            f'<a href="{DEM_URL}">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')


def work_page(src, path, title, body, menu_title, priority, refs):
    return f'''  - src: "{src}"
    path: "{path}"
    title: "{title}"
    menu: {{ title: "{menu_title}", priority: {priority} }}
    update: true
    body: |-
{block(body)}
    references: |-
{block(refs)}
'''


def main():
    books = contra_books()
    assert len(books) == 5, len(books)
    parts = []
    for i, (book_title, preface, chapters) in enumerate(books, 1):
        intro = (f'<p><em>Gegen die Häresien, Buch {i}, übersetzt von E. Klebba '
                 f'(Bibliothek der Kirchenväter, 1. Reihe, Bd. 3–4, München 1912).</em></p>')
        body = intro
        if preface:
            body += '<h2>0</h2>' + ''.join(preface)
        body += ''.join(f'<h2>{n}</h2>{text}' for n, text in chapters)
        refs = source('contra', i)
        print(f'  Buch {i}: {len(chapters)} Kapitel, {len(body)} байт')
        ru_path = ('Ириней_Лионский-Против_ересей' if i == 1 else
                   'Ириней_Лионский-Против_Ересей-2' if i == 2 else
                   f'Ириней_Лионский-Против_ересей-{i}')
        parts.append(work_page(ru_path,
                               f'Irenaeus_Gegen_die_Haeresien_{i}',
                               f'Gegen die Häresien — Buch {i}',
                               body, f'Gegen die Häresien — Buch {i}', i, refs))

    dem = demonstratio()
    dem_body = (f'<p><em>Erweis der apostolischen Verkündigung, übersetzt von E. Klebba '
                f'(Bibliothek der Kirchenväter, 1. Reihe, Bd. 4, München 1912).</em></p>'
                + dem)
    dem_refs = source('dem')
    print(f'  Demonstratio: {len(dem)} байт')
    parts.append(work_page('Ириней_Лионский-Доказательство_апостольской_проповеди',
                           'Irenaeus_Demonstratio',
                           'Erweis der apostolischen Verkündigung',
                           dem_body, 'Erweis der apostolischen Verkündigung', 6, dem_refs))

    works = ('# Ириней Лионский: труды (немецкая библиотека)\n'
             '# Сборка: script/translations/de/build_irenaeus.py\n\n'
             'lang: de\nlist: "Irenaeus_von_Lyon"\npages:\n\n' + '\n'.join(parts))
    path = os.path.join(DB, 'iren_works.yml')
    open(path, 'w', encoding='utf-8').write(works)
    print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')

    author_html = open(AUTHOR, encoding='utf-8').read().strip()
    author = f'''# Ириней Лионский: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_irenaeus.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "Ириней_Лионский"
    path: "Irenaeus_von_Lyon"
    title: "Irenäus von Lyon, 2. Jh."
    title_sub: "Hieromärtyrer (~130–202), Bischof von Lyon, frühchristlicher Theologe, Apologet, Polemiker, Kirchenvater, Schüler des Hieromärtyrers Polykarp von Smyrna"
    copy_cover: true
    menu: {{ parent: "2. Jahrhundert", title: "Irenäus von Lyon, Hieromärtyrer (~130–202)", replace: "Irenäus von Lyon, Hieromärtyrer (~130–202)", priority: 4 }}
    update: true
    body: |-
{block(author_html)}
'''
    path = os.path.join(DB, 'iren_author.yml')
    open(path, 'w', encoding='utf-8').write(author)
    print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
