#!/usr/bin/env python3
"""Сборка немецкого Афинагора: автор + две апологии (BKV 1913)."""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
DB = os.path.join(ROOT, 'db', 'translations', 'de')
OUT = os.path.join(ROOT, 'tmp', 'de_bkv', 'out')

AUTHOR = (
    '<h2>Biographie</h2>'
    '<p>Athenagoras von Athen (um 133 – um 190) war ein christlicher Philosoph und '
    'Apologet des 2. Jahrhunderts. Über sein Leben ist fast nichts bekannt; einer '
    'späteren Überlieferung zufolge war er ein Philosoph, der zum Christentum bekehrt '
    'wurde, als er die Schriften las mit der Absicht, gegen sie zu schreiben.</p>'
    '<p>Um 177 richtete er an die Kaiser Marc Aurel und Commodus „Bittschrift für die '
    'Christen“, in der er die Anschuldigungen des Atheismus, des Kannibalismus und der '
    'Blutschande gegen die Christen widerlegt und die christliche Lehre vom einen Gott '
    'und der Heiligen Dreifaltigkeit darlegt. Er schrieb auch die Abhandlung „Über die '
    'Auferstehung der Toten“. Seine Schriften zeichnen sich durch einen klaren '
    'philosophischen Stil und einen ruhigen, vernünftigen Ton aus.</p>'
)

SOURCE_SUPP = (
    '<p><strong>Quelle:</strong> Übersetzung von P. Anselm Eberhard, '
    '<em>Bittschrift für die Christen</em> (Bibliothek der Kirchenväter, 1. Reihe, Bd. 12), '
    'München 1913. Text nach '
    '<a href="https://bkv.unifr.ch/de/works/cpg-1070/versions/bittschrift-fur-die-christen-bkv">bkv.unifr.ch</a>; '
    'die Anmerkungen der Ausgabe sind weggelassen.</p>'
)
SOURCE_RES = (
    '<p><strong>Quelle:</strong> Übersetzung von P. Anselm Eberhard, '
    '<em>Über die Auferstehung der Toten</em> (Bibliothek der Kirchenväter, 1. Reihe, Bd. 12), '
    'München 1913. Text nach '
    '<a href="https://bkv.unifr.ch/de/works/cpg-1071/versions/uber-die-auferstehung-der-toten-bkv">bkv.unifr.ch</a>; '
    'die Anmerkungen der Ausgabe sind weggelassen.</p>'
)


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def page(src, path, title, body, refs, menu_title, priority, menu_parent=None):
    menu = f'{{ parent: "{menu_parent}", title: "{menu_title}", priority: {priority} }}' if menu_parent else f'{{ title: "{menu_title}", priority: {priority} }}'
    return f'''  - src: "{src}"
    path: "{path}"
    title: "{title}"
    menu: {menu}
    update: true
    body: |-
{block(body)}
    references: |-
{block(refs)}
'''


def main():
    supp = open(os.path.join(OUT, 'athen_supp.html'), encoding='utf-8').read().strip()
    res = open(os.path.join(OUT, 'athen_res.html'), encoding='utf-8').read().strip()
    author = f'''# Афинагор Афинский: страница автора (немецкая библиотека, с английского)
# Сборка: script/translations/de/build_athenagoras.py

lang: de
src_lang: en
list: "Kirchenvaeter"
pages:

  - src: "Athenagoras_of_Athens"
    path: "Athenagoras_von_Athen"
    title: "Athenagoras von Athen, 2. Jh."
    title_sub: "Christlicher Philosoph und Apologet (~133–190)"
    menu: {{ parent: "2. Jahrhundert", title: "Athenagoras von Athen, Philosoph und Apologet (~133–190)", priority: 7 }}
    update: true
    body: |-
{block(AUTHOR)}
'''
    works = f'''# Афинагор Афинский: две апологии (немецкая библиотека)
# Сборка: script/translations/de/build_athenagoras.py

lang: de
src_lang: en
list: "Athenagoras_von_Athen"
folders:
  - {{ path: "Werke", priority: 1 }}
pages:

{page('athenagoras-a-plea-for-the-christians', 'Athenagoras_Bittschrift', 'Bittschrift für die Christen', '<p><em>Bittschrift für die Christen, übersetzt von P. Anselm Eberhard (Bibliothek der Kirchenväter, 1. Reihe, Bd. 12, München 1913).</em></p>' + supp, SOURCE_SUPP, 'Bittschrift für die Christen', 1, 'Werke')}
{page('athenagoras-the-resurrection-of-the-dead', 'Athenagoras_Auferstehung', 'Über die Auferstehung der Toten', '<p><em>Über die Auferstehung der Toten, übersetzt von P. Anselm Eberhard (Bibliothek der Kirchenväter, 1. Reihe, Bd. 12, München 1913).</em></p>' + res, SOURCE_RES, 'Über die Auferstehung der Toten', 2, 'Werke')}
'''
    for name, text in (('athen_author.yml', author), ('athen_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
