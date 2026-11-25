#!/usr/bin/env python3
"""Обход страниц версий BKV: библиография, переводчик, ссылки на скачивание.

Каталог (`catalog.py`) даёт только автора/труд/тип/язык; чтобы понять права и
качество, нужна страница версии: там «Bibliographische Angabe» (переводчик,
издание, год), ссылки на EPUB/RTF/PDF и список делений.

Запуск (по умолчанию — только de/fr-переводы, с паузой 1.5 с):
  python3 script/translations/bkv/versions.py [--langs de,fr] [--limit 20] [--all]

Пишет tmp/bkv/versions/<slug>.json (кэш; повторный запуск не качает заново)
и tmp/bkv/versions.json — сводку.
"""
import argparse
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request

from lxml import html

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
TMP = os.path.join(ROOT, 'tmp', 'bkv')
CACHE = os.path.join(TMP, 'versions')
BASE = 'https://bkv.unifr.ch/de/works'

LANG_CODE = {'Deutsch': 'de', 'Englisch': 'en', 'Französisch': 'fr',
             'Lateinisch': 'la', 'Griechisch': 'grc', 'Koptisch': 'cop',
             'Italienisch': 'it'}

# маркеры источника в библиографии/названии; нужны для решения по правам
SOURCE_MARKERS = [
    ('bkv', r'\bBKV\b|Bibliothek der Kirchenväter'),
    ('swkv', r'\bSWKV\b|\bSKV\b'),
    ('anf', r'\bANF\b|\bNPNF\b|Ante-Nicene|Nicene and Post-Nicene'),
    ('ccel', r'CCEL|Christian Classics Ethereal'),
    ('loeb', r'Loeb'),
    ('genoude', r'Genoude|Genoud'),
    ('edith_stein', r'Edith Stein'),
    ('zeugen', r'Zeugen des Wortes|Rahner'),
    ('sources_chretiennes', r'Sources Chrétiennes'),
    ('chatgpt', r'ChatGPT'),
]


def fetch(url, path):
    if os.path.exists(path):
        return open(path, encoding='utf-8', errors='replace').read()
    req = urllib.request.Request(url, headers={'User-Agent': 'bibleox-library-import/1.0'})
    with urllib.request.urlopen(req, timeout=30) as r:
        data = r.read().decode('utf-8', 'replace')
    with open(path, 'w', encoding='utf-8') as f:
        f.write(data)
    return data


def parse(text):
    doc = html.fromstring(text)
    bib = ''
    for h in doc.xpath('//h3[contains(normalize-space(.),"Bibliographische Angabe")]'):
        p = h.xpath('following-sibling::p[1]')
        if p:
            bib = ' '.join(p[0].text_content().split())
            break
    files = sorted({a.get('href') for a in doc.xpath('//a[contains(@href,"/files/")]') if a.get('href')})
    collaborators = []
    for h in doc.xpath('//h3[contains(normalize-space(.),"Mitarbeiter")]'):
        nxt = h.xpath('following-sibling::*[1]')
        if nxt:
            collaborators.append(' '.join(nxt[0].text_content().split())[:300])
    return {'bibliography': bib, 'files': files, 'collaborators': collaborators}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--langs', default='de,fr')
    ap.add_argument('--limit', type=int, default=0)
    ap.add_argument('--all', action='store_true')
    ap.add_argument('--delay', type=float, default=1.5)
    args = ap.parse_args()

    catalog = json.load(open(os.path.join(TMP, 'catalog.json'), encoding='utf-8'))
    langs = None if args.all else set(args.langs.split(','))
    os.makedirs(CACHE, exist_ok=True)

    items = []
    for a in catalog['authors']:
        for w in a['works']:
            for v in w['versions']:
                code = LANG_CODE.get(v['lang'], '')
                if v['type'] != 'Übersetzung':
                    continue
                if langs is not None and code not in langs:
                    continue
                items.append({'author': a['author'], 'work': w['title'], 'work_id': w['id'],
                              'slug': v['slug'], 'title': v['title'], 'lang': code})

    if args.limit:
        items = items[:args.limit]

    out = []
    for i, item in enumerate(items, 1):
        path = os.path.join(CACHE, item['slug'].replace('/', '_') + '.json')
        url = '%s/%s/versions/%s' % (BASE, item['work_id'], urllib.parse.quote(item['slug']))
        data = {'url': url, **item}
        try:
            if not os.path.exists(path):
                page_path = os.path.join(CACHE, item['slug'].replace('/', '_') + '.html')
                fetch(url, page_path)
                data.update(parse(open(page_path, encoding='utf-8', errors='replace').read()))
                with open(path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False, indent=1)
                time.sleep(args.delay)
            else:
                data = json.load(open(path, encoding='utf-8'))
        except Exception as e:  # сеть/парсинг — не роняем весь обход
            data['error'] = str(e)
        out.append(data)
        if i % 25 == 0:
            print('  %d/%d' % (i, len(items)), file=sys.stderr)

    with open(os.path.join(TMP, 'versions.json'), 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=1)

    # сводка по маркерам
    counts = {k: 0 for k, _ in SOURCE_MARKERS}
    for d in out:
        text = (d.get('bibliography', '') + ' ' + d.get('title', '')).lower()
        for key, pat in SOURCE_MARKERS:
            if re.search(pat, text, re.I):
                counts[key] += 1
    print('версий разобрано:', len(out))
    for k, n in counts.items():
        print('  %-20s %4d' % (k, n))
    print('без библиографии:', sum(1 for d in out if not d.get('bibliography')))


if __name__ == '__main__':
    main()
