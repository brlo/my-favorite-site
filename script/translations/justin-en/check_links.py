#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Проверка ссылок собранной EN-страницы: страницы и анкоры существуют в dev-БД."""
import json, os, re, subprocess, sys, urllib.parse

HERE = os.path.dirname(os.path.abspath(__file__))
PSQL = ['docker', 'exec', 'bibpostgres', 'psql', '-U', 'bibleox', 'bibleox_development', '-t', '-A', '-c']


def q(sql):
    r = subprocess.run(PSQL + [sql], capture_output=True, text=True)
    if r.returncode:
        raise SystemExit(r.stderr)
    return r.stdout.strip()


def main(path):
    body = open(path, encoding='utf-8').read()
    links = sorted(set(re.findall(r'href="([^"]+)"', body)))
    bad = 0
    for url in links:
        if 'azbyka.ru' in url:
            print('внешняя (azbyka):', url[:70])
            continue
        m = re.match(r'https://bibleox\.com/(en|ru)/([a-z-]+)/w/([^#]*)', url)
        if not m:
            print('??', url)
            bad += 1
            continue
        lang, site, rest = m.group(1), m.group(2), urllib.parse.unquote(m.group(3))
        path, _, anchor = rest.partition('#')
        path = path.rstrip('/')
        row = q(f"SELECT id, body_rendered IS NOT NULL FROM pages WHERE lang='{site}' "
                f"AND path='{path.replace(chr(39), chr(39)*2)}' LIMIT 1")
        if not row:
            print('НЕТ СТРАНИЦЫ:', url)
            bad += 1
            continue
        pid, rendered = row.split('|')
        if not anchor:
            print('ok  ', url[:100])
            continue
        # анкор: id="HH-..." в отрендеренном теле
        anchor_esc = anchor.replace('"', '')
        found = q(f"SELECT 1 FROM pages WHERE id={pid} AND body_rendered LIKE "
                  f"'%id=\"{anchor_esc}\"%' LIMIT 1")
        if found:
            print('ok  ', url[:110])
        else:
            # страница могла не рендериться (body_rendered пуст) — проверим по body
            found2 = q(f"SELECT 1 FROM pages WHERE id={pid} AND body LIKE "
                       f"'%>{re.escape(anchor_esc).replace('%','')}<%'".replace("'", "'"))
            print('НЕТ АНКОРА:', url)
            bad += 1
    print('\nпроблем:', bad, 'из', len(links))


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'en_body.html'))
