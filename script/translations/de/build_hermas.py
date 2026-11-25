#!/usr/bin/env python3
"""Сборка немецкого «Пастыря Ерма» (BKV 1918)."""
import os
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402

DB = os.path.join(ROOT, 'db', 'translations', 'de')
EPUB = os.path.join(ROOT, 'tmp', 'de_bkv', 'herm.epub')

PREFACE = (
    '<h2>Vorwort</h2>'
    '<p>Der Verfasser der Schrift „Der Hirte des Hermas“ war Hermas, der Bruder des römischen Bischofs des heiligen Pius I. Der älteste Teil des „Hirten“ wurde noch zu Lebzeiten des heiligen Klemens geschrieben, das ganze Buch in seiner heutigen Gestalt jedoch erst um 130–140.</p>'
    '<p>Die Schrift entspricht im Umfang fast allen Werken der Zeit der apostolischen Väter zusammengenommen. Es ist ein apokalyptisches Buch: Der Autor sagt, er schreibe aufgrund einer Offenbarung als ein vom göttlichen Geist inspirierter Prophet.</p>'
    '<p>Einige der ältesten Väter rechneten das Buch zum Kanon des Neuen Testaments. Es gelangte auch in den berühmten Codex Sinaiticus zusammen mit den kanonischen biblischen Büchern.</p>'
    '<p>„Der Hirte des Hermas“ enthält fünf Gesichte, zwölf Gebote und zehn Gleichnisse. Die Offenbarungen werden Hermas durch die Kirche, die in Gestalt einer alten Frau erscheint, und durch den Engel, der in Gestalt eines Hirten erscheint, zuteil, woher der Name des Werkes stammt. Alle Offenbarungen, die Hermas empfing, enthalten Ermahnungen zur Buße.</p>'
    '<p>Im dritten Gesicht sah Hermas den Bau eines großen Turmes aus glänzenden quadratischen Steinen auf dem Wasser. Sechs Jünglinge bauten den Turm, und Tausende anderer Männer brachten Steine herbei. Der Deutung zufolge ist der Turm die Kirche auf Erden; die sechs Jünglinge sind die sechs erstgeschaffenen Engel, denen der Herr sein Schöpfungswerk anvertraut hat; die anderen Männer sind niedere Engel. Der Turm wird auf dem Wasser gebaut, um zu zeigen, dass das Leben durch das Wasser (d. h. das Sakrament der Taufe) gerettet ist und gerettet wird. Die sieben Frauen, die um den Turm stehen und ihn stützen, sind die sieben christlichen Tugenden: Glaube, Enthaltsamkeit, Einfalt, Unschuld, Bescheidenheit, Erkenntnis, Liebe. Der Bau des Turmes ist noch nicht vollendet, wird aber bald abgeschlossen sein, und dann wird das Ende kommen.</p>'
    '<p>Das fünfte Gesicht ist die Einleitung zu den Geboten und Gleichnissen. Die Gebote legen in einfacher Sprache die christliche Sittenlehre dar. So schreibt das zweite Gebot vor, in Einfalt und Arglistlosigkeit zu leben und Almosen zu geben, und im zehnten befiehlt der Hirt, Traurigkeit und Niedergeschlagenheit von sich zu entfernen und sich mit Freude zu bekleiden.</p>'
    '<p>Nach der Darlegung der Gebote geht der Hirt zu den zehn Gleichnissen über. Das erste gründet auf der Gleichsetzung der Christen mit den Bürgern der himmlischen Stadt, und im fünften Gleichnis lehrt der Hirt, dass das vollkommene und Gott wohlgefällige Fasten in der Enthaltung von der Sünde besteht. Das zehnte Gleichnis ist der Abschluss des ganzen Buches: „Zögert nicht, damit der Bau des Turmes nicht beendet wird... Wenn ihr euch nicht beeilt, euch zu bessern, wird der Turm vollendet, und ihr werdet nicht in ihn hineinkommen.“</p>'
)

SOURCE = (
    '<p><strong>Quelle:</strong> Übersetzung von Franz Zeller, '
    '<em>Der Hirte des Hermas</em> (Bibliothek der Kirchenväter, 1. Reihe, Bd. 35), '
    'München 1918. Text nach '
    '<a href="https://bkv.unifr.ch/de/works/cpg-1052/versions/der-hirte-des-hermas-bkv">bkv.unifr.ch</a>; '
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
    parts = ['<p><em>Der Hirte des Hermas, übersetzt von Franz Zeller '
             '(Bibliothek der Kirchenväter, 1. Reihe, Bd. 35, München 1918).</em></p>']
    for heading in doc.xpath('//h3'):
        title = ''.join(heading.itertext()).strip().rstrip('.')
        section = heading.getparent()
        paragraphs = ''.join(be.para_html(p) for p in section.xpath('.//p'))
        parts.append(f'<h2>{title}</h2>{paragraphs}')
    return ''.join(parts)


def main():
    work = work_body()
    work = PREFACE + work
    works = f'''# Пастырь Ерма (немецкая библиотека)
# Сборка: script/translations/de/build_hermas.py
# Меню после импорта переносит script/translations/de/unknown_authors_menu.rb.

lang: de
list: "Kirchenvaeter"
pages:

  - src: "Пастырь_Ерма"
    path: "Hirte_des_Hermas"
    title: "Hirte des Hermas"
    menu: {{ title: "Hirte des Hermas", priority: 10 }}
    update: true
    body: |-
{block(work)}
    references: |-
{block(SOURCE)}
'''
    path = os.path.join(DB, 'herm_works.yml')
    open(path, 'w', encoding='utf-8').write(works)
    print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
