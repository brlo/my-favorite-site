#!/usr/bin/env python3
"""Сборка немецкого Григория Чудотворца: автор, «Glaubensbekenntnis», «Lobrede»."""
import os
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402

DB = os.path.join(ROOT, 'db', 'translations', 'de')
TMP = os.path.join(ROOT, 'tmp', 'de_bkv')
AUTHOR = os.path.join(ROOT, 'script', 'translations', 'de', 'authors', 'gregor_wundertaeter.html')

SOURCE_CONF = (
    '<p><strong>Quelle:</strong> Übersetzung von Dr. P. Hermann Bourier, '
    '<em>Glaubenserklärung</em> (Bibliothek der Kirchenväter, 1. Reihe, Bd. 2), '
    'Kempten und München 1911. Text nach '
    '<a href="https://bkv.unifr.ch/de/works/cpg-1766/versions/glaubenserklarung-bkv">bkv.unifr.ch</a>; '
    'die Anmerkungen der Ausgabe sind weggelassen.</p>'
)
SOURCE_PAN = (
    '<p><strong>Quelle:</strong> Übersetzung von Dr. P. Hermann Bourier, '
    '<em>Lobrede auf Origenes</em> (Bibliothek der Kirchenväter, 1. Reihe, Bd. 2), '
    'Kempten und München 1911. Text nach '
    '<a href="https://bkv.unifr.ch/de/works/cpg-1765/versions/lobrede-auf-origenes-bkv">bkv.unifr.ch</a>; '
    'die Anmerkungen der Ausgabe sind weggelassen.</p>'
)


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def paragraphs(key):
    with zipfile.ZipFile(os.path.join(TMP, key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    return ''.join(be.para_html(p) for p in doc.xpath('//p'))


def page(src, path, title, body, refs, menu_title, priority, parent='Werke'):
    return f'''  - src: "{src}"
    path: "{path}"
    title: "{title}"
    menu: {{ parent: "{parent}", title: "{menu_title}", priority: {priority} }}
    update: true
    body: |-
{block(body)}
    references: |-
{block(refs)}
'''


def main():
    conf = ('<p><em>Glaubensbekenntnis, übersetzt von Dr. P. Hermann Bourier '
            '(Bibliothek der Kirchenväter, 1. Reihe, Bd. 2, Kempten und München 1911).</em></p>'
            + paragraphs('greg_conf'))
    pan = ('<p><em>Lobrede auf Origenes, übersetzt von Dr. P. Hermann Bourier '
           '(Bibliothek der Kirchenväter, 1. Reihe, Bd. 2, Kempten und München 1911).</em></p>')
    pan += open(os.path.join(TMP, 'out', 'greg_pan.html'), encoding='utf-8').read().strip()

    author_html = open(AUTHOR, encoding='utf-8').read().strip()
    author = f'''# Григорий Чудотворец: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_gregory.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "oJSu_Григорий_Чудотворец_III_век"
    path: "Gregor_der_Wundertäter"
    title: "Gregor der Wundertäter, 3. Jh."
    title_sub: "Heiliger (~213–270), erster Bischof von Neocäsarea. Der Überlieferung nach empfing er eine göttliche Offenbarung über das rechte Bekenntnis der Heiligen Dreifaltigkeit, die er im Glaubensbekenntnis niederschrieb."
    copy_cover: true
    menu: {{ parent: "3. Jahrhundert", title: "Gregor der Wundertäter, Bischof von Neocäsarea, Heiliger (~213–270)", replace: "Gregor der Wundertäter, Bischof von Neocäsarea, Heiliger (~213–270)", priority: 2 }}
    update: true
    body: |-
{block(author_html)}
'''
    works = f'''# Григорий Чудотворец: труды (немецкая библиотека)
# Сборка: script/translations/de/build_gregory.py

lang: de
list: "Gregor_der_Wundertäter"
folders:
  - {{ path: "Werke", priority: 1 }}
pages:

{page('RW7Q_Изложение_веры', 'Gregor_Glaubensbekenntnis', 'Glaubensbekenntnis', conf, SOURCE_CONF, 'Glaubensbekenntnis', 1)}
{page('AT7w_Благодарственная_речь_Оригену', 'Gregor_Lobrede_auf_Origenes', 'Lobrede auf Origenes', pan, SOURCE_PAN, 'Lobrede auf Origenes', 4)}
'''
    for name, text in (('greg_author.yml', author), ('greg_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
