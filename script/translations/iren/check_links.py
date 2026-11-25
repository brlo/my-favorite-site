#!/usr/bin/env python3
"""Проверка ссылок и якорей в собранном теле страницы."""
import json
import os
import re
import sys
import urllib.parse
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
TMP = os.environ.get('IREN_TMP') or HERE


def fetch(url):
    req = urllib.request.Request(url, headers={'User-Agent': 'bibleox-check/1.0'})
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.status, r.read().decode('utf-8', 'replace')


def main():
    lang = sys.argv[1]
    body = open(os.path.join(TMP, 'build', f'{lang}_body.html'), encoding='utf-8').read()
    hrefs = re.findall(r'href="([^"]+)"', body)
    cache = {}
    bad = []
    for href in sorted(set(hrefs)):
        if href.startswith('https://bibleox.com/'):
            url = href.replace('https://bibleox.com/', 'http://bibleox.lan/')
        elif href.startswith('https://azbyka.ru/'):
            continue
        else:
            bad.append(('внешняя', href))
            continue
        base, _, frag = url.partition('#')
        if base not in cache:
            try:
                status, html = fetch(base)
                ids = set(re.findall(r'id="([^"]*)"', html))
                cache[base] = (status, ids)
            except Exception as e:  # noqa: BLE001
                cache[base] = (0, set())
                print('ОШИБКА', base, e)
        status, ids = cache[base]
        if status != 200:
            bad.append((f'HTTP {status}', href))
        elif frag and frag not in ids and not frag.startswith('L'):
            bad.append(('нет якоря', href))
    print(f'{lang}: ссылок {len(set(hrefs))}, проблем {len(bad)}')
    for kind, href in bad:
        print('  !', kind, urllib.parse.unquote(href)[:160])


if __name__ == '__main__':
    main()
