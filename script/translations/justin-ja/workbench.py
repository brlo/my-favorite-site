#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Рабочая доска для зеркалирования выделений: ru-цитаты со спанами +
# ja-фрагменты (plain) по фрагментам. Выход: marks_workbench.md
import sys, os, json, re
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ju_author as J

HERE = os.path.dirname(os.path.abspath(__file__))
COMPOSITES = {12, 21, 28, 35, 40}

def build_parts():
    parts_all = {}
    for n in range(1, 96):
        spec = J.MANUAL.get(n) or [tuple(x) for x in J.AUTO[str(n)]]
        parts = []
        for (work, num, ps, pe, st, en) in spec:
            frag, err = J.extract_fragment(work, num, ps, pe, st, en)
            assert frag is not None, (n, err)
            parts.append(frag)
        parts_all[n] = parts
    for n, text in J.QTEXT.items():
        parts_all[n] = [text]
    return parts_all

def main():
    ru = json.load(open(os.path.join(HERE, 'ru_quotes.json'), encoding='utf-8'))
    parts_all = build_parts()
    out = []
    for n in range(1, 102):
        gs = ru[str(n)]
        parts = parts_all[n]
        comp = ' [КОМПОЗИТ]' if n in COMPOSITES else ''
        out.append(f'\n## Q{n}{comp}  ru-групп: {len(gs)}, ja-фрагментов: {len(parts)}\n')
        for gi, g in enumerate(gs):
            tag = f' [g{gi}]' if (n in COMPOSITES or len(gs) > 1) else ''
            out.append(f'--- ru{tag} ({len(g["plain"])} зн.) ---')
            out.append(g['text'])
            for sp in g['spans']:
                out.append(f'  <{sp["tag"]}> ({sp["s"]},{sp["e"]}) «{sp["text"]}»')
        for fi, frag in enumerate(parts):
            plain, _ = J.frag_map(frag)
            has_link = '<a ' in frag
            out.append(f'--- ja[f{fi}] ({len(plain)} зн.{", есть <a>" if has_link else ""}) ---')
            out.append(plain)
    path = os.path.join(HERE, 'marks_workbench.md')
    open(path, 'w', encoding='utf-8').write('\n'.join(out))
    # сводка: спаны ru по цитатам vs наличие в ja
    tot_ru = 0
    lines = []
    for n in range(1, 102):
        gs = ru[str(n)]
        cnt = sum(len(g['spans']) for g in gs)
        tot_ru += cnt
        lines.append(f'Q{n}:{cnt}')
    print('ru-спаны по цитатам:', ' '.join(lines))
    print('всего ru-спанов:', tot_ru)
    print('OK ->', path)

if __name__ == '__main__':
    main()
