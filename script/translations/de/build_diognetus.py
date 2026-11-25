#!/usr/bin/env python3
"""Сборка немецкого «Послания к Диогнету» (BKV 1913)."""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
DB = os.path.join(ROOT, 'db', 'translations', 'de')
SRC = os.path.join(ROOT, 'tmp', 'de_bkv', 'out', 'diog.html')

PARENT = (
    '<p>Hier werden die Werke unbekannter Autoren des 2. Jahrhunderts gesammelt.</p>'
)
SOURCE = (
    '<p><strong>Quelle:</strong> Übersetzung von Dr. Gerhard Rauschen, '
    '<em>Brief an Diognet</em> (Bibliothek der Kirchenväter, 1. Reihe, Bd. 12), '
    'München 1913. Text nach '
    '<a href="https://bkv.unifr.ch/de/works/cpg-1108/versions/brief-an-diognet-bkv">bkv.unifr.ch</a>; '
    'die Anmerkungen der Ausgabe sind weggelassen.</p>'
)


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def main():
    body = open(SRC, encoding='utf-8').read().strip()
    parent = f'''# Труды II века неизвестных авторов (немецкая библиотека)
# Сборка: script/translations/de/build_diognetus.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "Труды_II_века_неизвестных_авторов"
    path: "Werke_unbekannter_Autoren_des_2_Jahrhunderts"
    title: "Werke unbekannter Autoren des 2. Jahrhunderts"
    update: true
    body: |-
{block(PARENT)}
'''
    works = f'''# Послание к Диогнету (немецкая библиотека)
# Сборка: script/translations/de/build_diognetus.py

lang: de
list: "Werke_unbekannter_Autoren_des_2_Jahrhunderts"
folders:
  - {{ path: "Briefe", priority: 1 }}
  - {{ path: "Schriften", priority: 2 }}
pages:

  - src: "Псл_Дгнт"
    path: "Diognetus_Brief"
    title: "Brief an Diognet"
    menu: {{ parent: "Briefe", title: "Brief an Diognet", priority: 1 }}
    update: true
    body: |-
{block('<p><em>Brief an Diognet, übersetzt von Dr. Gerhard Rauschen (Bibliothek der Kirchenväter, 1. Reihe, Bd. 12, München 1913).</em></p>' + body)}
    references: |-
{block(SOURCE)}
'''
    for name, text in (('diog_parent.yml', parent), ('diog_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
