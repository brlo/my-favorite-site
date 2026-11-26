#!/usr/bin/env python3
"""Сборка немецкого Кирилла Иерусалимского: автор + два труда (BKV)."""
import os
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
DB = os.path.join(ROOT, 'db', 'translations', 'de')
OUT = os.path.join(ROOT, 'tmp', 'de_bkv', 'out')

AUTHOR = (
    '<p>Gedenktag: 18. (31.) März</p>'
    '<h2>Biographie</h2>'
    '<p>Kirchenvater, Bischof von Jerusalem (350–386), Asket und Prediger, der bestrebt war, die Bedeutung Jerusalems als Zentrum der gesamten christlichen Kirche zu erhöhen. Jerusalem war damals dem Metropoliten von Cäsarea unterstellt, was den heiligen Cyrill keineswegs zufriedenstellte. Dreimal wurde er auf Betreiben des Bischofs von Cäsarea, Akakios, abgesetzt, der von Cyrill die Annahme des Arianismus verlangte. Anlässlich eines himmlischen Zeichens – der Erscheinung des Kreuzes des Herrn am Himmel über Jerusalem am Pfingstfest 351 – sandte Cyrill den „Brief an den frommen Kaiser Constantius“. Cyrill verwendete viel Kraft auf die Befriedung der Jerusalemer Herde und den Kampf gegen die Häretiker, gegen die er auf dem Zweiten Ökumenischen Konzil die Verurteilung unterzeichnete.</p>'
    '<h2>Hymnographie</h2>'
    '<p><strong>Kondak des heiligen Cyrill, Erzbischof von Jerusalem, 4. Ton</strong></p>'
    '<blockquote><p><em>Mit deiner Zunge, du Weiser, / hast du durch göttliche Eingebungen dein Volk erleuchtet, / die eine Dreieinigkeit zu verehren, / von Natur ungeteilt, in den Personen aber geteilt. / Darum feiern wir freudig dein allheiliges Gedächtnis, // und tragen dich als Fürbitter zu Gott empor.</em></p></blockquote>'
)

SOURCES = {
    'cat': ('Katechesen an die Täuflinge', 'https://bkv.unifr.ch/de/works/cpg-3585/versions/katechesen-an-die-tauflinge-bkv'),
    'myst': ('Mystagogische Katechesen an die Neugetauften', 'https://bkv.unifr.ch/de/works/cpg-3586/versions/mystagogische-katechesen-an-die-neugetauften-bkv'),
}


sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402


def sections(key):
    with zipfile.ZipFile(os.path.join(ROOT, 'tmp', 'de_bkv', 'cyr_' + key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for i, heading in enumerate(doc.xpath('//h2'), 1):
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        parts.append(f'<h2>{i}</h2>{body}')
    return ''.join(parts)


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def source(key):
    title, url = SOURCES[key]
    return (f'<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>{title}</em> '
            f'(Bibliothek der Kirchenväter). Text nach <a href="{url}">bkv.unifr.ch</a>; '
            f'die Anmerkungen der Ausgabe sind weggelassen.</p>')


def page(src, path, title, key, priority):
    body = (f'<p><em>{title} (Bibliothek der Kirchenväter).</em></p>' + sections(key))
    return f'''  - src: "{src}"
    path: "{path}"
    title: "{title}"
    menu: {{ parent: "Katechetische Werke", title: "{title}", priority: {priority} }}
    update: true
    body: |-
{block(body)}
    references: |-
{block(source(key))}
'''


def main():
    author = f'''# Кирилл Иерусалимский: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_cyril.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "rXYx_Кирилл_Иерусалимский_IV_век"
    path: "Cyrill_von_Jerusalem"
    title: "Cyrill von Jerusalem, 4. Jh."
    title_sub: "Heiliger (315–386), Kirchenvater, Bischof von Jerusalem (350–386), Asket und Prediger"
    copy_cover: true
    menu: {{ parent: "4. Jahrhundert", title: "Cyrill von Jerusalem, Heiliger (315–386)", replace: "Cyrill von Jerusalem, Heiliger (315–386)", priority: 9 }}
    update: true
    body: |-
{block(AUTHOR)}
'''
    works = f'''# Кирилл Иерусалимский: труды (немецкая библиотека)
# Сборка: script/translations/de/build_cyril.py

lang: de
list: "Cyrill_von_Jerusalem"
folders:
  - {{ path: "Katechetische Werke", priority: 1 }}
pages:

{page('Wocw_Поучения_огласительные', 'Cyrill_Katechesen', 'Katechesen an die Täuflinge', 'cat', 1)}
{page('gKkn_Тайноводственные_поучения', 'Cyrill_Mystagogische_Katechesen', 'Mystagogische Katechesen an die Neugetauften', 'myst', 2)}
'''
    for name, text in (('cyr_author.yml', author), ('cyr_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
