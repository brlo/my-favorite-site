#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Таблица для глазной сверки: ru-цитата ↔ en-цитата (начало) + where."""
import json, os, re, glob, sys, html

HERE = os.path.dirname(os.path.abspath(__file__))


def plain(s):
    s = re.sub(r'<[^>]+>', '', s)
    return re.sub(r'\s+', ' ', html.unescape(s)).strip()


def main():
    blocks = json.load(open(os.path.join(HERE, 'blocks.json'), encoding='utf-8'))
    quotes = {}
    for fn in glob.glob(os.path.join(HERE, 'out', '*.json')):
        quotes.update(json.load(open(fn, encoding='utf-8')))
    sys.path.insert(0, HERE)
    import review_quotes
    for q, v in review_quotes.build().items():
        quotes[('q', q)] = v
    only = sys.argv[1:] and set(int(x) for x in sys.argv[1:])
    for b in blocks:
        if b['type'] != 'quote':
            continue
        if only and b['q'] not in only:
            continue
        val = quotes.get(str(b['id'])) or quotes.get(('q', b['q']))
        if not val:
            print(f'Q{b["q"]}: НЕТ')
            continue
        ru = ' / '.join(plain(p) for g in b['groups'] for p in g)
        en = ' / '.join(plain(p) for p in val['quote'] if '&lt;…&gt;' not in p)
        print(f'Q{b["q"]}  [{val.get("where","")}]')
        print('  RU:', ru[:260])
        print('  EN:', en[:260])
        print()


if __name__ == '__main__':
    main()
