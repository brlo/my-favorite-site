#!/usr/bin/env python3
"""Сборка немецкого Минуция Феликса («Октавий») из EPUB BKV 1913."""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
DB = os.path.join(ROOT, 'db', 'translations', 'de')
SRC = os.path.join(ROOT, 'tmp', 'de_bkv', 'out', 'minuc.html')

AUTHOR = (
    '<h2>Biographie</h2>'
    '<p>Der lateinische Schriftsteller Marcus Minucius Felix wurde in Afrika als Heide geboren. '
    'Er erhielt eine gute rhetorische Ausbildung und wurde römischer Anwalt. '
    'Er bekehrte sich erst im reifen Alter zum Christentum, erschüttert durch die '
    'erhabene Lehre des Evangeliums und den Mut der christlichen Märtyrer.</p>'
)

WORK_INTRO = (
    '<p><em>Dialog Octavius, übersetzt von Dr. Alfons Müller '
    '(Bibliothek der Kirchenväter, 1. Reihe, Bd. 14, München 1913).</em></p>'
)
SOURCE = (
    '<p><strong>Quelle:</strong> Übersetzung von Dr. Alfons Müller, '
    '<em>Frühchristliche Apologeten</em> (Bibliothek der Kirchenväter, 1. Reihe, Bd. 14), '
    'München 1913. Text nach '
    '<a href="https://bkv.unifr.ch/de/works/cpl-37/versions/dialog-octavius-bkv">bkv.unifr.ch</a>; '
    'die Anmerkungen der Ausgabe sind weggelassen. Die Schlussbemerkungen (in der russischen Ausgabe Kap. 41) stehen in der BKV-Ausgabe am Ende von Kap. 40.</p>'
)


def q(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def main():
    body = open(SRC, encoding='utf-8').read().strip()
    author = f'''# Минуций Феликс: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_minucius.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "Марк_Минуций_Феликс"
    path: "Minuzius_Felix"
    title: "Minucius Felix, 3. Jh."
    title_sub: "(† um 250)"
    menu: {{ parent: "3. Jahrhundert", title: "Minucius Felix († um 250)", replace: "Minucius Felix († um 250)", priority: 3 }}
    update: true
    body: |-
{block(AUTHOR)}
'''
    works = f'''# Минуций Феликс: «Октавий» (немецкая библиотека)
# Сборка: script/translations/de/build_minucius.py

lang: de
list: "Minuzius_Felix"
pages:

  - src: "Марк_Минуций_Феликс-Октавий"
    path: "MinFl_Octavius"
    title: "Octavius"
    menu: {{ title: "Octavius", priority: 1 }}
    update: true
    body: |-
{block(WORK_INTRO + body)}
    references: |-
{block(SOURCE)}
'''
    for name, text in (('minuc_author.yml', author), ('minuc_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
