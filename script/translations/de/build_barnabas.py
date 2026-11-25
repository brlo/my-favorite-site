#!/usr/bin/env python3
"""Сборка немецкого Варнавы: автор + «Barnabasbrief» (BKV 1918)."""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
DB = os.path.join(ROOT, 'db', 'translations', 'de')
SRC = os.path.join(ROOT, 'tmp', 'de_bkv', 'out', 'barn.html')
AUTHOR = os.path.join(ROOT, 'script', 'translations', 'de', 'authors', 'barnabas.html')

SOURCE = (
    '<hr><p><strong>Quelle:</strong> Übersetzung von Franz Zeller, '
    '<em>Barnabasbrief</em> (Bibliothek der Kirchenväter, 1. Reihe, Bd. 35), '
    'München 1918. Text nach '
    '<a href="https://bkv.unifr.ch/de/works/cpg-1050/versions/barnabasbrief-bkv">bkv.unifr.ch</a>; '
    'die Anmerkungen der Ausgabe sind weggelassen.</p>'
)


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def main():
    body = open(SRC, encoding='utf-8').read().strip()
    work = ('<p><em>Barnabasbrief, übersetzt von Franz Zeller '
            '(Bibliothek der Kirchenväter, 1. Reihe, Bd. 35, München 1918).</em></p>'
            + body + SOURCE)
    author_html = open(AUTHOR, encoding='utf-8').read().strip()
    author = f'''# Варнава, апостол: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_barnabas.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "Апостол_Варнава"
    path: "Barnabas"
    title: "Barnabas, Apostel, 1. Jh."
    title_sub: "Apostel aus den Siebzig, Gründer der Kirche von Zypern, Begleiter des Apostels Paulus auf seinen Missionsreisen († um 57)"
    # В RU страница автора намеренно без ссылки из библиотеки (авторство спорно);
    # после импорта меню правит script/translations/de/unknown_authors_menu.rb.
    update: true
    body: |-
{block(author_html)}
'''
    works = f'''# Варнава, апостол: «Barnabasbrief» (немецкая библиотека)
# Сборка: script/translations/de/build_barnabas.py

lang: de
list: "Barnabas"
pages:

  - src: "Послание-апостола-Варнавы"
    path: "Barnabasbrief"
    title: "Barnabasbrief"
    menu: {{ title: "Barnabasbrief", priority: 1 }}
    update: true
    body: |-
{block(work)}
'''
    for name, text in (('barn_author.yml', author), ('barn_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
