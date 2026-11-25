#!/usr/bin/env python3
"""Сборка немецкого Киприана Карфагенского: автор + три трактата (BKV 1918)."""
import os
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402

DB = os.path.join(ROOT, 'db', 'translations', 'de')
TMP = os.path.join(ROOT, 'tmp', 'de_bkv')
AUTHOR = os.path.join(ROOT, 'script', 'translations', 'de', 'authors', 'cyprian.html')

SOURCES = {
    'unit': ('Über die Einheit der katholischen Kirche', 'https://bkv.unifr.ch/de/works/cpl-41/versions/uber-die-einheit-der-katholischen-kirche-bkv'),
    'mort': ('Über die Sterblichkeit', 'https://bkv.unifr.ch/de/works/cpl-44/versions/uber-die-sterblichkeit-bkv'),
    'zelo': ('Über Eifersucht und Neid', 'https://bkv.unifr.ch/de/works/cpl-49/versions/uber-eifersucht-und-neid-bkv'),
}


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def paragraphs(key):
    with zipfile.ZipFile(os.path.join(TMP, 'cyp_' + key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    return ''.join(be.para_html(p) for p in doc.xpath('//p'))


def source(key):
    title, url = SOURCES[key]
    return (f'<p><strong>Quelle:</strong> Übersetzung von Julius Baer, '
            f'<em>{title}</em> (Bibliothek der Kirchenväter, 1. Reihe, Bd. 34), '
            f'München 1918. Text nach <a href="{url}">bkv.unifr.ch</a>; '
            f'die Anmerkungen der Ausgabe sind weggelassen.</p>')


def page(src, path, title, key, menu_title, priority):
    body = (f'<p><em>{title}, übersetzt von Julius Baer '
            f'(Bibliothek der Kirchenväter, 1. Reihe, Bd. 34, München 1918).</em></p>'
            + paragraphs(key))
    return f'''  - src: "{src}"
    path: "{path}"
    title: "{title}"
    menu: {{ parent: "Abhandlungen", title: "{menu_title}", priority: {priority} }}
    update: true
    body: |-
{block(body)}
    references: |-
{block(source(key))}
'''


def main():
    author_html = open(AUTHOR, encoding='utf-8').read().strip()
    author = f'''# Киприан Карфагенский: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_cyprian.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "Киприан_Карфагенский_III_век"
    path: "Cyprian_von_Karthago"
    title: "Cyprian von Karthago, 3. Jh."
    title_sub: "Hieromärtyrer (~200–258), Bischof von Karthago, geistlicher Schriftsteller, Apologet"
    copy_cover: true
    menu: {{ parent: "3. Jahrhundert", title: "Cyprian von Karthago, Hieromärtyrer (~200–258)", replace: "Cyprian von Karthago, Hieromärtyrer (~200–258)", priority: 1 }}
    update: true
    body: |-
{block(author_html)}
'''
    works = f'''# Киприан Карфагенский: трактаты (немецкая библиотека)
# Сборка: script/translations/de/build_cyprian.py

lang: de
list: "Cyprian_von_Karthago"
folders:
  - {{ path: "Abhandlungen", priority: 2 }}
pages:

{page('fqde5EZK_О_единстве_Церкви_De_unitate__Киприан_Карфагенский', 'Cyprian_De_unitate', 'Über die Einheit der katholischen Kirche', 'unit', 'Über die Einheit der katholischen Kirche', 5)}
{page('sTfINaYq_Книга_о_смертности__Киприан_Карфагенский', 'Cyprian_De_mortalitate', 'Über die Sterblichkeit', 'mort', 'Über die Sterblichkeit', 9)}
{page('Vvl2JTrw_Книга_о_ревности_и_зависти__Киприан_Карфагенский', 'Cyprian_De_zelo', 'Über Eifersucht und Neid', 'zelo', 'Über Eifersucht und Neid', 12)}
'''
    for name, text in (('cyp_author.yml', author), ('cyp_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
