#!/usr/bin/env python3
"""Сборка немецкого Ипполита Римского: «О Христе и антихристе» (BKV 1872)."""
import os
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402

DB = os.path.join(ROOT, 'db', 'translations', 'de')
EPUB = os.path.join(ROOT, 'tmp', 'de_bkv', 'hipp_ant.epub')

AUTHOR = (
    '<p>Über den heiligen Hippolyt sind sehr wenige historische Nachrichten erhalten. '
    'Sie sind bruchstückhaft und lückenhaft, zudem weichen die in den Werken verschiedener '
    'Autoren festgehaltenen Angaben über ihn in vielem voneinander ab, was es unmöglich '
    'macht, seine Person genau zu identifizieren und ein vollständiges und zuverlässiges '
    'Verzeichnis seiner Schriften zu erstellen. Nach der verbreitetsten Hypothese war '
    'Hippolyt der Führer des rigoristischen Teils der römischen Kirche, der gegen den '
    'heiligen Märtyrer Callistus, den römischen Bischof, auftrat und in Rom eine alternative '
    'Gemeinde gründete, die auch während der beiden folgenden Pontifikate fortbestand. '
    'Dennoch zeigt der gegenwärtige Stand der Forschung zu diesem Problem, dass seine Lösung '
    'durch keine Kombination der vorhandenen Quellen möglich ist. Vielleicht erfolgte im '
    '6. Jahrhundert eine Identifizierung dieser heiligen Person mit dem heiligen Märtyrer '
    'Hippolyt, der an der Via Tiburtina begraben wurde.</p>'
)
SOURCE = (
    '<p><strong>Quelle:</strong> Übersetzung von Valentin Gröne, '
    '<em>Das Buch über Christus und den Antichrist</em> (Bibliothek der Kirchenväter, '
    '1. Serie, Bd. 28), Kempten 1872. Text nach '
    '<a href="https://bkv.unifr.ch/de/works/cpg-1910/versions/das-buch-uber-christus-und-den-antichrist-bkv">bkv.unifr.ch</a>; '
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
    parts = ['<p><em>Über Christus und den Antichrist, übersetzt von Valentin Gröne '
             '(Bibliothek der Kirchenväter, 1. Serie, Bd. 28, Kempten 1872).</em></p>']
    parts += [be.para_html(p) for p in doc.xpath('//p')]
    return ''.join(parts)


def main():
    author = f'''# Ипполит Римский: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_hippolytus.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "nPd5_Ипполит_Римский_IIIII_вв"
    path: "Hippolyt_von_Rom"
    title: "Hippolyt von Rom, 2.–3. Jh."
    title_sub: "Hieromärtyrer (170–235), frühchristlicher Schriftsteller; oft mit einem der römischen Märtyrer, einem Presbyter oder Bischof, identifiziert."
    copy_cover: true
    menu: {{ parent: "3. Jahrhundert", title: "Hippolyt von Rom, Hieromärtyrer (~170–235)", replace: "Hippolyt von Rom, Hieromärtyrer (~170–235)", priority: 3 }}
    update: true
    body: |-
{block(AUTHOR)}
'''
    works = f'''# Ипполит Римский: «О Христе и антихристе» (немецкая библиотека)
# Сборка: script/translations/de/build_hippolytus.py

lang: de
list: "Hippolyt_von_Rom"
folders:
  - {{ path: "Exegetische Werke", priority: 1 }}
pages:

  - src: "QtfU_Слово_о_Христе_и_антихристе"
    path: "Hippolyt_Antichrist"
    title: "Über Christus und den Antichrist"
    menu: {{ parent: "Exegetische Werke", title: "Über Christus und den Antichrist", priority: 1 }}
    update: true
    body: |-
{block(work_body())}
    references: |-
{block(SOURCE)}
'''
    for name, text in (('hipp_author.yml', author), ('hipp_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
