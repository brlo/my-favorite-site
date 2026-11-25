#!/usr/bin/env python3
"""Сборка YAML для страницы автора Иринея (en/grc)."""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TMP = os.environ.get('IREN_TMP') or HERE
ROOT = os.path.dirname(os.path.dirname(TMP))

META = {
    'en': {
        'list': 'q-saints-en',
        'path': 'Irenaeus_of_Lyon',
        'title': 'Irenaeus of Lyon, 2nd c.',
        'title_sub': ('hieromartyr (~130-202), bishop of Lyon, early Christian theologian, '
                      'apologist, polemicist, Church father, disciple of the holy martyr '
                      'Polycarp of Smyrna'),
        'meta_desc': ('Irenaeus of Lyon, hieromartyr and bishop of Lyon, disciple of Polycarp '
                      'of Smyrna: his life, his teaching on God and the Trinity, on Christ and '
                      'the incarnation, on the Church and Tradition, on the sacraments and the '
                      'last things, in his own words.'),
    },
    'grc': {
        'list': 'church_writers_grc',
        'path': '5tBI_Εἰρηναῖος_Λουγδούνου_2ος_αἰ',
        'title': 'Εἰρηναῖος Λουγδούνου, 2ος αἰ.',
        'title_sub': ('ιερομάρτυς (~130-202), επίσκοπος Λουγδούνου, πρωτοχριστιανός θεολόγος, '
                      'απολογητής, αντιρρητικός συγγραφέας, Πατέρας της Εκκλησίας, μαθητής του '
                      'ιερομάρτυρα Πολύκαρπου Σμύρνης'),
        'meta_desc': ('Ο Ειρηναίος Λουγδούνου, ιερομάρτυρας και επίσκοπος Λουγδούνου, μαθητής '
                      'του Πολυκάρπου Σμύρνης: ο βίος του, η διδασκαλία του για τον Θεό και την '
                      'Τριάδα, τον Χριστό και την ενανθρώπηση, την Εκκλησία και την Παράδοση, '
                      'τα μυστήρια και τα έσχατα, με τα δικά του λόγια.'),
    },
}

REFS = {
    'en': open(os.path.join(HERE, 'refs_en.html'), encoding='utf-8').read().strip(),
    'grc': open(os.path.join(HERE, 'refs_grc.html'), encoding='utf-8').read().strip(),
}


def block(text, indent=6):
    return '\n'.join(' ' * indent + line if line else '' for line in text.split('\n'))


def main():
    lang = sys.argv[1]
    body = open(os.path.join(TMP, 'build', f'{lang}_body.html'), encoding='utf-8').read()
    meta = META[lang]
    yaml = f'''# Ириней Лионский: страница автора ({lang})
# Сборка: tmp/iren/assemble.py + tmp/iren/build_yaml.py

lang: {lang}
list: "{meta['list']}"
pages:

  - src: "Ириней_Лионский"
    path: "{meta['path']}"
    title: "{meta['title']}"
    title_sub: "{meta['title_sub']}"
    meta_desc: "{meta['meta_desc']}"
    copy_cover: true
    update: true
    body: |-
{block(body)}
    references: |-
{block(REFS[lang], 6)}
'''
    out = os.path.join(ROOT, 'db', 'translations', lang, 'irenaeus_author.yml')
    open(out, 'w', encoding='utf-8').write(yaml)
    print('написан', out, len(yaml), 'байт')


if __name__ == '__main__':
    main()
