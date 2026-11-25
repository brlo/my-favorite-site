#!/usr/bin/env python3
"""Разбирает индекс BKV (https://bkv.unifr.ch/de/works) в JSON-каталог.

Одна страница индекса содержит весь каталог: авторы (accordion-card header),
труды (h3 + ссылка /works/<id>), версии (li a: тип, язык, название, slug).
Права и выходные данные версии (переводчик, год, издание) в индексе не видны —
их надо брать со страницы версии отдельным проходом.

Запуск: python3 script/translations/bkv/catalog.py
Пишет tmp/bkv/catalog.json и печатает сводку.
"""
import json
import os
import re
import sys

from lxml import html

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
SRC = os.path.join(ROOT, 'tmp', 'bkv', 'works.html')
OUT = os.path.join(ROOT, 'tmp', 'bkv', 'catalog.json')

TYPE_RE = re.compile(r'^(Edition|Übersetzung|Kommentar)\s*\(([^)]+)\)$')


def parse(path):
    doc = html.parse(path)
    cards = []
    for card in doc.xpath('//accordion-card'):
        author = (card.get('header') or '').strip()
        works = []
        for h3 in card.xpath('.//h3'):
            link = h3.xpath('./a')
            if not link:
                continue
            href = link[0].get('href') or ''
            m = re.search(r'/works/([^/]+)$', href)
            if not m:
                continue
            title = ' '.join(h3.text_content().split())
            versions = []
            uls = h3.xpath('following-sibling::ul[1]')
            if uls:
                for a in uls[0].xpath('./li/a'):
                    small = a.xpath('./small')
                    kind = small[0].text_content().strip() if small else ''
                    tm = TYPE_RE.match(kind)
                    vtype, lang = (tm.group(1), tm.group(2)) if tm else (kind, '')
                    vhref = a.get('href') or ''
                    vm = re.search(r'/versions/([^/]+)', vhref)
                    versions.append({
                        'slug': vm.group(1) if vm else '',
                        'type': vtype,
                        'lang': lang,
                        'title': ' '.join(a.text_content().split()),
                    })
            works.append({'id': m.group(1), 'title': title, 'versions': versions})
        cards.append({'author': author, 'works': works})
    return cards


def main():
    if not os.path.exists(SRC):
        sys.exit('нет %s: скачайте https://bkv.unifr.ch/de/works' % SRC)
    cards = parse(SRC)
    with open(OUT, 'w', encoding='utf-8') as f:
        json.dump({'authors': cards}, f, ensure_ascii=False, indent=1)

    works = [w for c in cards for w in c['works']]
    versions = [v for w in works for v in w['versions']]
    print('авторов:', len(cards))
    print('трудов:', len(works))
    print('версий:', len(versions))
    print('трудов без версий:', sum(1 for w in works if not w['versions']))
    print()
    print('по языкам:')
    for lang in sorted({v['lang'] for v in versions}):
        print('  %-14s %4d' % (lang, sum(1 for v in versions if v['lang'] == lang)))
    print()
    print('по типам:')
    for t in sorted({v['type'] for v in versions}):
        print('  %-14s %4d' % (t, sum(1 for v in versions if v['type'] == t)))
    print()
    print('версий с (BKV) в названии:', sum(1 for v in versions if '(BKV)' in v['title']))


if __name__ == '__main__':
    main()
