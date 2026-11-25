#!/usr/bin/env python3
"""Сборка немецкого Григория Нисского: автор + три труда (BKV)."""
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
AUTHOR = os.path.join(ROOT, 'script', 'translations', 'de', 'authors', 'gregor_nyssa.html')

SOURCES = {
    'kate': ('Große Katechese', 'https://bkv.unifr.ch/de/works/cpg-3150/versions/grosse-katechese-bkv',
             'Übersetzung der BKV-Ausgabe', 'BKV 1. Reihe, Bd. 56, Kempten/München 1927'),
    'opif': ('Abhandlung über die Ausstattung des Menschen', 'https://bkv.unifr.ch/de/works/cpg-3154/versions/abhandlung-uber-die-ausstattung-des-menschen-bkv',
             'Heinrich Hand', 'BKV 1. Serie, Bd. 24, Kempten 1874'),
    'orat': ('Das Gebet des Herrn', 'https://bkv.unifr.ch/de/works/cpg-3160/versions/das-gebet-des-herrn-bkv',
             'Übersetzung der BKV-Ausgabe', 'BKV 1. Reihe, Bd. 56, Kempten/München 1927'),
}
ORDINALS = {'Erste': 1, 'Zweite': 2, 'Dritte': 3, 'Vierte': 4, 'Fünfte': 5}


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def sections(key):
    with zipfile.ZipFile(os.path.join(TMP, 'nys_' + key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for heading in doc.xpath('//h2'):
        title = ''.join(heading.itertext()).strip()
        number = None
        m = re.search(r'Kapitel\s+(\d+)', title)
        if m:
            number = int(m.group(1))
        elif title.startswith('Vorwort') or title.startswith('Gregor,'):
            number = 0
        else:
            for word, value in ORDINALS.items():
                if title.startswith(word):
                    number = value
                    break
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        parts.append(f'<h2>{number if number is not None else 0}</h2>{body}')
    return ''.join(parts)


def source(key):
    title, url, translator, edition = SOURCES[key]
    return (f'<p><strong>Quelle:</strong> Übersetzung von {translator}, '
            f'<em>{title}</em> ({edition}). Text nach '
            f'<a href="{url}">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')


def page(src, path, title, key, priority):
    body = (f'<p><em>{title}, übersetzt von {SOURCES[key][2]} '
            f'({SOURCES[key][3]}).</em></p>' + sections(key))
    return f'''  - src: "{src}"
    path: "{path}"
    title: "{title}"
    menu: {{ parent: "Werke", title: "{title}", priority: {priority} }}
    update: true
    body: |-
{block(body)}
    references: |-
{block(source(key))}
'''


def main():
    author_html = open(AUTHOR, encoding='utf-8').read().strip()
    author = f'''# Григорий Нисский: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_nyssa.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "Григорий_Нисский"
    path: "Gregor_von_Nyssa"
    title: "Gregor von Nyssa, 4. Jh."
    title_sub: "Heiliger (~331–394), Bischof von Nyssa, Kirchenvater, Theologe und Mystiker"
    copy_cover: true
    menu: {{ parent: "4. Jahrhundert", title: "Gregor von Nyssa, Heiliger (~331–394)", replace: "Gregor von Nyssa, Heiliger (~331–394)", priority: 4 }}
    update: true
    body: |-
{block(author_html)}
'''
    works = f'''# Григорий Нисский: труды (немецкая библиотека)
# Сборка: script/translations/de/build_nyssa.py

lang: de
list: "Gregor_von_Nyssa"
folders:
  - {{ path: "Werke", priority: 1 }}
pages:

{page('L4vk_Большое_огласительное_слово', 'Gregor_Nyssa_Grosse_Katechese', 'Große Katechese', 'kate', 1)}
{page('UXHY_Об_устроении_человека', 'Gregor_Nyssa_Ausstattung_des_Menschen', 'Abhandlung über die Ausstattung des Menschen', 'opif', 2)}
{page('URHE_Беседы_о_молитве_Господней', 'Gregor_Nyssa_Gebet_des_Herrn', 'Das Gebet des Herrn', 'orat', 3)}
'''
    for name, text in (('nyssa_author.yml', author), ('nyssa_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
