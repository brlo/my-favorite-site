#!/usr/bin/env python3
"""Сборка немецкого Евсевия Кесарийского: автор + 10 книг «Kirchengeschichte»."""
import os
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402

DB = os.path.join(ROOT, 'db', 'translations', 'de')
EPUB = os.path.join(ROOT, 'tmp', 'de_bkv', 'eus_he.epub')
URL = 'https://bkv.unifr.ch/de/works/cpg-3495/versions/kirchengeschichte-bkv-2'

AUTHOR = (
    '<p><strong><mark>Eusebius vertrat gemäßigte arianische Ansichten und war zudem '
    'Origenist. Man muss auch berücksichtigen, dass er Hofhistoriker Kaiser Konstantins '
    'war und wie ein Hofhistoriker schrieb. Beim Lesen des Eusebius muss man also all '
    'diese Eigentümlichkeiten des Historikers in Rechnung stellen und unter ihrer '
    'Berücksichtigung den Grad des Vertrauens bestimmen, mit dem man seinen Schriften '
    'begegnen sollte.</mark></strong></p>'
    '<p>Der Bereich mit den Werken des Eusebius von Cäsarea <strong>in griechischer '
    'Sprache</strong>: <a href="https://bibleox.com/de/grc/w/%CE%95%CF%85%CF%83%CE%AD%CE%B2%CE%B9%CE%BF%CF%82_%CE%9A%CE%B1%CE%B9%CF%83%CE%B1%CF%81%CE%B5%CE%AF%CE%B1%CF%82_%CE%A0%CE%AC%CE%BC%CF%86%CE%B9%CE%BB%CE%BF%CF%82_III-IV_%CE%B1%CE%B9/">hier</a>. '
    'Der Wechsel in andere Sprachen ist ebenfalls oben über der Werkliste möglich.</p>'
    '<h2>Biographie</h2>'
    '<p>Eusebius wurde in Palästina geboren und in den Schulen von Jerusalem und '
    'Antiochien ausgebildet. Er studierte die Werke Platons und Philons von Alexandrien; '
    'besonders prägend war für ihn die Lehre des Origenes. Den Beinamen „Pamphilus“, '
    'genauer „des Pamphilus“ (Εὐσέβιος ὁ Παμφίλου), erhielt er wegen seiner Freundschaft '
    'mit einem gewissen Presbyter Pamphilus; später wurde dieser Beiname als sein zweiter '
    'eigener Name verstanden.</p>'
    '<p>Während der Verfolgung unter Diokletian war er einer der Leiter der Katechetenschule '
    'von Cäsarea; es gelang ihm, deren Bibliothek zu retten und sogar durch neue Handschriften '
    'zu bereichern. Als die Streitigkeiten über die Natur Christi begannen, ergriff er eher '
    'aus persönlichen als aus theologischen Gründen Partei für Arius.</p>'
    '<p>Auf dem Ersten Ökumenischen Konzil trat er auf und schlug als versöhnliche Formel '
    'die Verwendung des Taufbekenntnisses vor. Dieser Vorschlag wurde angenommen, das '
    'Bekenntnis selbst aber um den Begriff „wesensgleich“ ergänzt. Eusebius stimmte dem '
    '„um des Kirchenfriedens willen“ zu, neigte aber bis zu seinem Lebensende dem '
    'Semiarianismus zu und verwandte sich beim Kaiser Konstantin für seine Gesinnungsgenossen.</p>'
    '<p>Trotz der Fragwürdigkeit seiner dogmatischen Ansichten gilt Eusebius von Cäsarea '
    'zu Recht als Vater der Kirchengeschichte. Sein bekanntestes Werk ist der Geschichte '
    'des Christentums bis zum Jahr 324 gewidmet und schöpft aus kirchlichen wie staatlichen '
    'Archiven. Daran schließt sich der berühmte Panegyrikus „Leben Konstantins“ sowie '
    'kleinere Arbeiten über die Geschichte der Märtyrer an.</p>'
    '<p>Ihm gehören auch theologische Werke: „Vorbereitung auf das Evangelium“, „Beweis '
    'für das Evangelium“, „Gegen Hierokles“, „Auszug aus den Propheten über Christus“, '
    '„Theophanie“, „Zwei Bücher gegen Marcellus“, „Drei Bücher über die kirchliche '
    'Theologie“ und andere.</p>'
)

SOURCE = (
    '<p><strong>Quelle:</strong> Übersetzung von Phil. Häuser, '
    '<em>Kirchengeschichte</em> (Bibliothek der Kirchenväter, 2. Reihe, Bd. 1), '
    'München 1932. Text nach <a href="' + URL + '">bkv.unifr.ch</a>; '
    'die Anmerkungen der Ausgabe sind weggelassen.</p>'
)


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def books():
    with zipfile.ZipFile(EPUB) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    result = []
    for book in doc.xpath('//section[contains(@class,"level2")]'):
        chapters = []
        for section in book.xpath('./section'):
            heading = section.find('h3')
            number = be.chapter_number(heading) if heading is not None else None
            body = ''.join(be.para_html(p) for p in section.xpath('.//p'))
            if body:
                chapters.append((number, body))
        result.append(chapters)
    return result


def page(n, chapters):
    body = (f'<p><em>Kirchengeschichte, Buch {n}, übersetzt von Phil. Häuser '
            f'(Bibliothek der Kirchenväter, 2. Reihe, Bd. 1, München 1932).</em></p>')
    for number, text in chapters:
        body += f'<h2>{number if number is not None else 0}</h2>{text}'
    return f'''  - src: "Церковная_история_книга_{n}_—_Евсевий_Кесарийский"
    path: "Eusebius_Kirchengeschichte_{n}"
    title: "Kirchengeschichte — Buch {n}"
    menu: {{ parent: "Geschichte", title: "Buch {n}", priority: {n} }}
    update: true
    body: |-
{block(body)}
    references: |-
{block(SOURCE)}
'''


def main():
    author = f'''# Евсевий Кесарийский: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_eusebius.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "Евсевий_Кесарийский_(Памфил),_IV_век"
    path: "Eusebius_von_Cäsarea"
    title: "Eusebius von Cäsarea (Pamphilus), 4. Jh."
    title_sub: "(~258–339) Bischof von Cäsarea in Palästina, Kirchenhistoriker und Schriftsteller, Theologe, Apologet, Ausleger der Heiligen Schrift"
    menu: {{ parent: "4. Jahrhundert", title: "Eusebius von Cäsarea, Bischof (~258–339)", replace: "Eusebius von Cäsarea, Bischof (~258–339)", priority: 4 }}
    update: true
    body: |-
{block(AUTHOR)}
'''
    parts = '\n'.join(page(i, ch) for i, ch in enumerate(books(), 1))
    works = f'''# Евсевий Кесарийский: «Kirchengeschichte» (немецкая библиотека)
# Сборка: script/translations/de/build_eusebius.py
# Меню после импорта правит script/translations/de/eusebius_menu.rb.

lang: de
list: "Eusebius_von_Cäsarea"
folders:
  - {{ path: "Geschichte", priority: 1 }}
pages:

{parts}'''
    for name, text in (('eus_author.yml', author), ('eus_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
