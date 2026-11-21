#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Сборка пакетов-источников для переводчиков-агентов: блоки раздела + главы ANF."""
import json, os, re

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'chunks')
os.makedirs(OUT, exist_ok=True)

SEP = '<p>&lt;…&gt;</p>'
WORKS = {'A1': 'en_ap1.html', 'A2': 'en_ap2.html', 'Dial': 'en_dial.html'}

CHUNKS = {
    'c1': (1, 11), 'c2': (12, 45), 'c3': (46, 59), 'c4': (60, 88),
    'c5': (89, 108), 'c6': (109, 143), 'c7': (144, 185), 'c8': (186, 210),
    'c9': (211, 239), 'c10a': (240, 263), 'c10b': (264, 285), 'c11': (286, 307),
}


def chapters(work):
    h = open(os.path.join(HERE, WORKS[work]), encoding='utf-8').read()
    parts = re.split(r'<h2[^>]*>(.*?)</h2>', h)
    d = {}
    for i in range(1, len(parts), 2):
        d[parts[i].strip()] = parts[i + 1]
    return d


def plain(html):
    return re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', '', html)).strip()


def main():
    blocks = json.load(open(os.path.join(HERE, 'blocks.json'), encoding='utf-8'))
    ch = {w: chapters(w) for w in WORKS}
    for name, (a, b) in CHUNKS.items():
        bs = [x for x in blocks if a <= x['id'] <= b]
        used = []
        lines = [f'# Пакет {name}: блоки {a}-{b} (ru-страница Иустина)', '']
        for x in bs:
            t = x['type']
            if t == 'quote':
                lines.append(f"[B{x['id']} Q{x['q']}]  (ja-указание: {x['annex']})")
                for gi, g in enumerate(x['groups']):
                    if gi:
                        lines.append('  ' + SEP)
                    for p in g:
                        lines.append('  ' + p)
                if x['source']:
                    lines.append(f"  источник в ru: {x['source']['title']}{x['source']['tail']}")
                lines.append('')
                if x['annex']:
                    used.append((x['annex']['work'], x['annex']['chapter']))
            elif t == 'source':
                continue
            else:
                lines.append(f"[B{x['id']} {t}] {x['html']}")
                lines.append('')
        lines.append('')
        lines.append('## Тексты ANF (en, дословный источник цитат)')
        lines.append('')
        seen = set()
        for w, n in used:
            key = (w, n)
            if key in seen:
                continue
            seen.add(key)
            txt = ch[w].get(str(n))
            if txt is None:
                lines.append(f'### {w} {n} — главы нет в файле')
                continue
            lines.append(f'### {w} {n}')
            lines.append(plain(txt))
            lines.append('')
        open(os.path.join(OUT, name + '.md'), 'w', encoding='utf-8').write('\n'.join(lines))
        print(name, 'блоков', len(bs), 'глав', len(seen),
              'размер', os.path.getsize(os.path.join(OUT, name + '.md')))


if __name__ == '__main__':
    main()
