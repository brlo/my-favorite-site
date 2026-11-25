#!/usr/bin/env python3
"""Сборка немецкого Афанасия Великого: автор + три труда (BKV 1917)."""
import os
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402

DB = os.path.join(ROOT, 'db', 'translations', 'de')
TMP = os.path.join(ROOT, 'tmp', 'de_bkv')
OUT = os.path.join(TMP, 'out')
AUTHOR = os.path.join(ROOT, 'script', 'translations', 'de', 'authors', 'athanasius.html')

SOURCES = {
    'gent': ('Gegen die Heiden', 'https://bkv.unifr.ch/de/works/cpg-2090/versions/gegen-die-heiden-bkv'),
    'inc': ('Über die Menschwerdung des Logos', 'https://bkv.unifr.ch/de/works/cpg-2091/versions/uber-die-menschwerdung-des-logos-und-dessen-leibliche-erscheinung-unter-uns-bkv'),
    'vita': ('Leben des heiligen Antonius', 'https://bkv.unifr.ch/de/works/cpg-2101/versions/leben-des-heiligen-antonius-bkv'),
}


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def paragraphs(key):
    with zipfile.ZipFile(os.path.join(TMP, 'ath_' + key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    return ''.join(be.para_html(p) for p in doc.xpath('//p'))


def source(key):
    title, url = SOURCES[key]
    return (f'<p><strong>Quelle:</strong> Übersetzung von Anton Stegmann und Hans Mertel, '
            f'<em>{title}</em> (Bibliothek der Kirchenväter, 1. Reihe, Bd. 31), '
            f'München 1917. Text nach <a href="{url}">bkv.unifr.ch</a>; '
            f'die Anmerkungen der Ausgabe sind weggelassen.</p>')


def page(src, path, title, key, body, priority):
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
    gent = paragraphs('gent')
    inc = open(os.path.join(OUT, 'ath_inc.html'), encoding='utf-8').read().strip()
    vita = open(os.path.join(OUT, 'ath_vita.html'), encoding='utf-8').read().strip()
    author_html = open(AUTHOR, encoding='utf-8').read().strip()
    author = f'''# Афанасий Великий: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_athanasius.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "Афанасий-Великий"
    path: "Athanasius_der_Große"
    title: "Athanasius der Große, 4. Jh."
    title_sub: "Heiliger (~295–373), Erzbischof von Alexandrien, Kirchenvater und Kirchenlehrer, Verteidiger des nicäischen Glaubens"
    copy_cover: true
    menu: {{ parent: "4. Jahrhundert", title: "Athanasius der Große, Heiliger (~295–373)", replace: "Athanasius der Große, Heiliger (~295–373)", priority: 1 }}
    update: true
    body: |-
{block(author_html)}
'''
    works = f'''# Афанасий Великий: труды (немецкая библиотека)
# Сборка: script/translations/de/build_athanasius.py

lang: de
list: "Athanasius_der_Große"
folders:
  - {{ path: "Werke", priority: 1 }}
pages:

{page('8vHZ_Слово_на_язычников', 'Athanasius_Gegen_die_Heiden', 'Gegen die Heiden', 'gent', '<p><em>Gegen die Heiden, übersetzt von Anton Stegmann und Hans Mertel (Bibliothek der Kirchenväter, 1. Reihe, Bd. 31, München 1917).</em></p>' + gent, 1)}
{page('QFHf_Слово_о_воплощении_БогаСлова', 'Athanasius_Menschwerdung', 'Über die Menschwerdung des Logos', 'inc', '<p><em>Über die Menschwerdung des Logos, übersetzt von Anton Stegmann und Hans Mertel (Bibliothek der Kirchenväter, 1. Reihe, Bd. 31, München 1917).</em></p>' + inc, 2)}
{page('5Wxn_Житие_преп_Антония_Великого', 'Athanasius_Leben_des_Antonius', 'Leben des heiligen Antonius', 'vita', '<p><em>Leben des heiligen Antonius, übersetzt von Anton Stegmann und Hans Mertel (Bibliothek der Kirchenväter, 1. Reihe, Bd. 31, München 1917).</em></p>' + vita, 3)}
'''
    for name, text in (('athan_author.yml', author), ('athan_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
