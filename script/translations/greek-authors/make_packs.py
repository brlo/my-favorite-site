#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Пакеты для агентов: ru-блоки страницы + тексты греческих глав."""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
SEP = '<p>&lt;…&gt;</p>'

# блоки страницы -> пакеты
CHUNKS = {
    'ign': {'a': (1, 18), 'b': (19, 49), 'c': (50, 81), 'd': (82, 109), 'e': (110, 124)},
    'pol': {'a': (1, 23), 'b': (24, 64)},
}
EPISTLES = ['Ef', 'Mag', 'Tral', 'Rom', 'Phil', 'Smyr', 'Pol']
# какие труды давать в пакете
PACK_WORKS = {
    'igna': ['PlkFl', 'Eus3'], 'ignb': EPISTLES, 'ignc': EPISTLES, 'ignd': EPISTLES,
    'igne': ['PlkFl', 'Eus3'],
    'pola': ['Mart', 'Eus3'], 'polb': ['PlkFl', 'Mart'],
}
HINTS = {
    'ign': 'Послания Игнатия (Ef, Mag, Tral, Rom, Phil, Smyr, Pol), Послание Поликарпа (PlkFl), Евсевий «Церковная история» кн. 3 (Eus3)',
    'pol': 'Послание Поликарпа (PlkFl), Мученичество Поликарпа (Mart), Евсевий «Церковная история» кн. 3 (Eus3)',
}


def plain_html(s):
    import re
    return re.sub(r'\s+', ' ', re.sub('<[^>]+>', '', s)).strip()


def main(page):
    blocks = json.load(open(os.path.join(HERE, f'blocks_{page}.json'), encoding='utf-8'))
    works = json.load(open(os.path.join(HERE, 'works.json'), encoding='utf-8'))
    os.makedirs(os.path.join(HERE, 'chunks'), exist_ok=True)
    for name, (a, b) in CHUNKS[page].items():
        bs = [x for x in blocks if a <= x['id'] <= b]
        lines = [f'# Пакет {page}{name}: блоки {a}-{b}', '',
                 f'Доступные труды: {HINTS[page]}', '']
        for x in bs:
            t = x['type']
            if t == 'quote':
                src = (x['source']['title'] + x['source']['tail']) if x['source'] else '—'
                lines.append(f"[B{x['id']} Q{x['q']}]  (источник в ru: {src})")
                for gi, g in enumerate(x['groups']):
                    for pi, p in enumerate(g):
                        lines.append(f'  ru[{gi}.{pi}]: {p}')
                lines.append('')
            elif t == 'source':
                continue
            elif t == 'table':
                lines.append(f"[B{x['id']} table] (таблица — её переводит координатор)")
                lines.append('')
            else:
                lines.append(f"[B{x['id']} {t}] {x['html']}")
                lines.append('')
        lines.append('')
        lines.append('## Греческие тексты трудов (нумерация абзацев снята)')
        lines.append('')
        for w in PACK_WORKS[f'{page}{name}']:
            lines.append(f'### {w}')
            chs = ['36'] if w == 'Eus3' else list(works[w])
            for ch in chs:
                for i, p in enumerate(works[w][ch]):
                    lines.append(f'[{ch}.{i}] {p}')
            lines.append('')
        path = os.path.join(HERE, 'chunks', f'{page}{name}.md')
        open(path, 'w', encoding='utf-8').write('\n'.join(lines))
        print(path, 'блоков', len(bs), 'размер', os.path.getsize(path))


if __name__ == '__main__':
    main(sys.argv[1])
