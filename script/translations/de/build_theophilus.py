#!/usr/bin/env python3
"""Сборка немецкого Феофила Антиохийского («К Автолику») из EPUB BKV 1913."""
import os
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402

DB = os.path.join(ROOT, 'db', 'translations', 'de')
EPUB = os.path.join(ROOT, 'tmp', 'de_bkv', 'theoph.epub')

AUTHOR = (
    '<h2>Biographie</h2>'
    '<p>Gedenktag: 13. (26.) Oktober</p>'
    '<p>Theophilus von Antiochien (griech. Θεόφιλος Αντιοχείας) wurde in Syrien geboren. '
    'Nach der «Kirchengeschichte» des Eusebius war Theophilus der sechste Bischof von '
    'Antiochien nach den Aposteln.</p>'
    '<p>Er stammte aus einer heidnischen Familie. Er war ein gut gebildeter Mann und '
    'studierte die griechische Literatur. Das zeigt sich in seiner einzigen erhaltenen '
    'Schrift (An Autolykus): Er zitiert Dichter, Historiker und heidnische Philosophen. '
    'Vor seiner Annahme des Christentums studierte er die Bücher des Alten Testaments '
    '(vor allem die prophetischen). Danach überzeugte er sich von der unbestreitbaren '
    'Überlegenheit des Christentums über andere Religionen. Auf ähnlichen Wegen kamen '
    'auch seine Zeitgenossen Justin der Philosoph, Athenagoras von Athen und Tatian zum '
    'Christentum. Als Heide war Theophilus ein erbitterter Gegner des Christentums; '
    'nachdem er den christlichen Glauben angenommen hatte, wurde er zu dessen eifrigem '
    'Verteidiger und Bekenner.</p>'
    '<p>Er hatte den antiochenischen Stuhl 168 inne. Wie lange Theophilus Bischof war, '
    'ist nicht genau bekannt. Bekannt ist, dass er während der Regierung des römischen '
    'Kaisers Commodus, in den 80er Jahren des zweiten Jahrhunderts, starb.</p>'
    '<p>Leider sind alle zahlreichen Schriften des Theophilus verloren gegangen. Bekannt '
    'ist nur, dass darunter Schriften gegen Häretiker (Gnostizismus, die Lehre Markions), '
    'gegen Heiden sowie apologetische und polemische Schriften waren.</p>'
    '<p>Den Begriff «Trinität» verwendete in seinen Schriften als erster Theophilus: '
    '«Die drei Tage [der Schöpfung]», sagt der Apologet, «die vor [der Erschaffung] der '
    'Gestirne waren, sind Bilder der Trinität (τύποι είσι της τριάδος): Gottes, seines '
    'Wortes und seiner Weisheit».</p>'
)

SOURCE = (
    '<hr><p><strong>Quelle:</strong> Übersetzung von J. Leitl, '
    '<em>Frühchristliche Apologeten</em> (Bibliothek der Kirchenväter, 1. Reihe, Bd. 14), '
    'München 1913. Text nach '
    '<a href="https://bkv.unifr.ch/de/works/cpg-1107/versions/an-autolykus-bkv">bkv.unifr.ch</a>; '
    'die Anmerkungen der Ausgabe sind weggelassen.</p>'
)


def q(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def work_body():
    with zipfile.ZipFile(EPUB) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    books = doc.xpath('//section[contains(@class,"level2")]')
    parts = ['<p><em>Drei Bücher an Autolykus, übersetzt von J. Leitl '
             '(Bibliothek der Kirchenväter, 1. Reihe, Bd. 14, München 1913).</em></p>']
    for number, book in enumerate(books[:3], 1):
        parts.append(f'<h2>{number}</h2>')
        for p in book.xpath('.//section[contains(@class,"level3")]//p'):
            parts.append(be.para_html(p))
    return ''.join(parts)


def main():
    author = f'''# Феофил Антиохийский: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_theophilus.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "Феофил_Антиохийский"
    path: "Theophilus_von_Antiochien"
    title: "Theophilus von Antiochien, 2. Jh."
    title_sub: "Heiliger, christlicher Schriftsteller, Apologet und Polemiker († 183)"
    menu: {{ parent: "2. Jahrhundert", title: "Theophilus von Antiochien, Heiliger († 183)", replace: "Theophilus von Antiochien, Heiliger († 183)", priority: 3 }}
    update: true
    body: |-
{block(AUTHOR)}
'''
    works = f'''# Феофил Антиохийский: «An Autolykus» (немецкая библиотека)
# Сборка: script/translations/de/build_theophilus.py

lang: de
list: "Theophilus_von_Antiochien"
pages:

  - src: "Феофил-послание_к_Автолику"
    path: "Theophilus_Autolykus"
    title: "An Autolykus"
    menu: {{ title: "An Autolykus", priority: 1 }}
    update: true
    body: |-
{block(work_body() + SOURCE)}
'''
    for name, text in (('theoph_author.yml', author), ('theoph_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
