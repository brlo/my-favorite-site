#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Верификация MARKS: резолв всех спанов по фактическим фрагментам, наложение,
# сводка applied/skipped и показ результата для глазной проверки.
import sys, os, json, re
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ju_author as J
from workbench import build_parts

HERE = os.path.dirname(os.path.abspath(__file__))

def main():
    ru = json.load(open(os.path.join(HERE, 'ru_quotes.json'), encoding='utf-8'))
    parts_all = build_parts()
    show = set(int(x) for x in sys.argv[1:]) if len(sys.argv) > 1 else set()
    tot_ru = tot_ap = tot_skip = 0
    rows = []
    for n in sorted(parts_all):
        parts = parts_all[n]
        ru_cnt = sum(len(g['spans']) for g in ru[str(n)])
        entries = J.MARKS.get(n, [])
        # резолв + наложение с asserts
        new_parts, applied, skipped = J.apply_quote_marks(n, parts)
        tot_ru += ru_cnt
        tot_ap += len(entries)
        tot_skip += ru_cnt - len(entries)
        rows.append((n, ru_cnt, len(entries), ru_cnt - len(entries)))
        if n in show:
            for fi, frag in enumerate(new_parts):
                print(f'--- Q{n}[f{fi}] ---')
                print(frag)
    print('\nцитата  ru-спанов  перенесено  пропущено')
    for n, rc, ap, sk in rows:
        if rc or ap:
            print(f'Q{n:<4}  {rc:<9}  {ap:<10}  {sk}')
    print(f'\nИТОГО: ru={tot_ru}, авторских записей={tot_ap}, пропущено={tot_skip}')

if __name__ == '__main__':
    main()
