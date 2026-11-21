#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Пакеты для агентов (греческая страница): ru-блоки + тексты греческих глав."""
import json, os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'chunks')
os.makedirs(OUT, exist_ok=True)
SEP = '<p>&lt;…&gt;</p>'

CHUNKS = {
    'g1': (12, 45), 'g2': (46, 59), 'g3': (60, 88), 'g4': (89, 108),
    'g5': (109, 143), 'g6': (144, 185), 'g7': (186, 210), 'g8': (211, 239),
    'g9a': (240, 263), 'g9b': (264, 285),
}
NAMES = {'A1': 'Ἀπολογία 1', 'A2': 'Ἀπολογία 2', 'Dial': 'Διάλογος πρὸς Τρύφωνα'}


def main():
    blocks = json.load(open(os.path.join(HERE, 'blocks.json'), encoding='utf-8'))
    works = json.load(open(os.path.join(HERE, 'works.json'), encoding='utf-8'))
    for name, (a, b) in CHUNKS.items():
        bs = [x for x in blocks if a <= x['id'] <= b]
        lines = [f'# Пакет {name}: блоки {a}-{b} (ru-страница Иустина, цитаты — греческий оригинал)', '']
        used = []
        for x in bs:
            if x['type'] == 'quote':
                lines.append(f"[B{x['id']} Q{x['q']}]  (подсказка: {x['annex']})")
                for gi, g in enumerate(x['groups']):
                    for pi, p in enumerate(g):
                        lines.append(f'  ru[{gi}.{pi}]: {p}')
                if x['source']:
                    lines.append(f"  источник в ru: {x['source']['title']}")
                lines.append('')
                if x['annex']:
                    used.append((x['annex']['work'], x['annex']['chapter']))
            elif x['type'] == 'source':
                continue
            else:
                lines.append(f"[B{x['id']} {x['type']}] {x['html']}")
                lines.append('')
        lines.append('')
        lines.append('## Греческие тексты глав (дословный источник цитат; нумерация абзацев снята)')
        lines.append('')
        seen = set()
        for w, ch in used:
            key = (w, str(ch))
            if key in seen:
                continue
            seen.add(key)
            paras = works[w].get(str(ch))
            if not paras:
                lines.append(f'### {w} {ch} — главы нет')
                continue
            lines.append(f'### {w} {ch}')
            for i, p in enumerate(paras):
                lines.append(f'[{i}] {p}')
            lines.append('')
        open(os.path.join(OUT, name + '.md'), 'w', encoding='utf-8').write('\n'.join(lines))
        print(name, 'блоков', len(bs), 'глав', len(seen),
              'размер', os.path.getsize(os.path.join(OUT, name + '.md')))


if __name__ == '__main__':
    main()
