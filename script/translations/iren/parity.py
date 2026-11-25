#!/usr/bin/env python3
"""Паритет структуры: RU-эталон (457) против собранного тела."""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TMP = os.environ.get('IREN_TMP') or HERE

TAGS = ['h2', 'h3', 'blockquote', 'p', 'strong', 'em', 'mark', 'u', 'li']


def counts(html):
    return {t: len(re.findall(rf'<{t}[ >]', html)) for t in TAGS}


def main():
    lang = sys.argv[1]
    ru = open(os.path.join(TMP, 'db', '457.html'), encoding='utf-8').read()
    body = open(os.path.join(TMP, 'build', f'{lang}_body.html'), encoding='utf-8').read()
    c1, c2 = counts(ru), counts(body)
    print(f'{"тег":12s} {"RU":>4s} {"target":>7s}')
    for t in TAGS:
        mark = '' if c1[t] == c2[t] else ('  <-- ' + ('меньше' if c2[t] < c1[t] else 'больше'))
        print(f'{t:12s} {c1[t]:4d} {c2[t]:7d}{mark}')
    for name, html in (('RU', ru), ('target', body)):
        txt = re.sub('<[^>]+>', '', html)
        print(name, 'знаков текста:', len(txt))


if __name__ == '__main__':
    main()
