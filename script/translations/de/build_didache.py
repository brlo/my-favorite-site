#!/usr/bin/env python3
"""Сборка немецкой Дидахе: страница «Werke unbekannter Autoren» + труд."""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
DB = os.path.join(ROOT, 'db', 'translations', 'de')
SRC = os.path.join(ROOT, 'tmp', 'de_bkv', 'out', 'did.html')

PARENT = (
    '<p>Es gibt eine Reihe alter Texte, deren Urheberschaft sich nicht sicher feststellen '
    'lässt. Es werden verschiedene Versionen vorgeschlagen. Diese Werke des 1. Jahrhunderts '
    'werden dieser Seite zugeordnet.</p>'
)
SOURCE = (
    '<p><strong>Quelle:</strong> Übersetzung von Franz Zeller, '
    '<em>Lehre der zwölf Apostel</em> (Bibliothek der Kirchenväter, 1. Reihe, Bd. 35), '
    'München 1918. Text nach '
    '<a href="https://bkv.unifr.ch/de/works/cpg-1753/versions/didache-lehre-der-zwolf-apostel-bkv">bkv.unifr.ch</a>; '
    'die Anmerkungen der Ausgabe sind weggelassen.</p>'
)


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def main():
    body = open(SRC, encoding='utf-8').read().strip().replace('<h2>0</h2>', '')
    work = (f'<p><em>Lehre der zwölf Apostel, übersetzt von Franz Zeller '
            f'(Bibliothek der Kirchenväter, 1. Reihe, Bd. 35, München 1918).</em></p>'
            + body)
    parent = f'''# Труды I века неизвестных авторов (немецкая библиотека)
# Сборка: script/translations/de/build_didache.py
# После импорта меню (категории «Unterweisungen»/«Übriges») правит
# script/translations/de/unknown_authors_menu.rb.

lang: de
list: "Kirchenvaeter"
pages:

  - src: "1-век-труды-неизвестных-авторов"
    path: "Werke_unbekannter_Autoren_des_1_Jahrhunderts"
    title: "Werke unbekannter Autoren des 1. Jahrhunderts"
    menu: {{ parent: "1. Jahrhundert", title: "Werke unbekannter Autoren des 1. Jahrhunderts", replace: "Werke unbekannter Autoren des 1. Jahrhunderts", priority: 250 }}
    update: true
    body: |-
{block(PARENT)}
'''
    works = f'''# Дидахе (немецкая библиотека)
# Сборка: script/translations/de/build_didache.py
# После импорта меню (категории «Unterweisungen»/«Übriges») правит
# script/translations/de/unknown_authors_menu.rb.

lang: de
list: "Werke_unbekannter_Autoren_des_1_Jahrhunderts"
pages:

  - src: "Дидахе"
    path: "Didache_Lehre_der_zwolf_Apostel"
    title: "Didache — Lehre der zwölf Apostel"
    menu: {{ title: "Didache — Lehre der zwölf Apostel", priority: 1 }}
    update: true
    body: |-
{block(work)}
    references: |-
{block(SOURCE)}
'''
    for name, text in (('did_parent.yml', parent), ('did_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
