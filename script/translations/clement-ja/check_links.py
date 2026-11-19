#!/usr/bin/env python3
# Проверка всех ссылок в body_rendered + references_rendered трёх страниц Климента (ja):
# страницы существуют, якоря #HH- есть в целевой странице, стихи jp-ni существуют.
import re
import subprocess
import sys
from urllib.parse import unquote

PAGES = {
    'author': 'Kl1A_ローマのクレメンス1世紀',
    'cor1': 'Kl1C1_コリントの教会への手紙第一',
    'cor2': 'Kl1C2_コリントの教会への手紙第二',
}

SQL = "SELECT body_rendered || ' ' || coalesce(references_rendered, '') FROM pages WHERE path_low = '{low}' AND lang='ja';"


def sql(query):
    r = subprocess.run(['docker', 'exec', 'bibpostgres', 'psql', '-U', 'bibleox',
                        'bibleox_development', '-t', '-A', '-c', query],
                       capture_output=True, text=True)
    return r.stdout.strip()


def page_exists(path_low):
    return sql(f"SELECT count(*) FROM pages WHERE path_low='{path_low}' AND is_deleted IS NOT TRUE;") != '0'


def heading_anchors(path_low):
    body = sql(f"SELECT body FROM pages WHERE path_low='{path_low}' LIMIT 1;")
    anchors = set()
    for m in re.finditer(r'<h([234])>(.*?)</h\1>', body):
        t = re.sub(r'<[^>]+>', '', m.group(2))
        t = re.sub(r'[^\w\s\-]', '', t, flags=re.UNICODE)
        anchors.add('HH-' + t.strip().replace(' ', '-'))
    return anchors


def verse_exists(tr, addr):
    # addr: book:ch:verse (первый стих диапазона)
    n = sql(f"SELECT count(*) FROM verses WHERE tr_code='{tr}' AND address='{addr}';")
    return n != '0'


errors = []
for key, path in PAGES.items():
    low = path.lower()
    html = sql(SQL.format(low=low))
    if not html:
        errors.append(f'{key}: страница не найдена')
        continue
    hrefs = re.findall(r'href="([^"]+)"', html)
    seen = set()
    for href in hrefs:
        if href in seen:
            continue
        seen.add(href)
        if href.startswith('#'):
            # якорь на этой же странице
            m = re.match(r'#(HH-.+|cite_note-\d+)$', href)
            if m and href.startswith('#HH-'):
                if href[1:] not in heading_anchors(low):
                    errors.append(f'{key}: локальный якорь {href}')
            continue
        m = re.match(r'https://bibleox\.com/ja/(ja|grc|en|ru)/w/([^/#]+)(#.+)?$', href)
        if m:
            lang, p, anc = m.groups()
            p_low = unquote(p).lower()
            if not page_exists(p_low):
                errors.append(f'{key}: нет страницы {href}')
                continue
            if anc:
                tgt_low = sql(f"SELECT path_low FROM pages WHERE path_low='{p_low}' LIMIT 1;")
                anchors = heading_anchors(tgt_low)
                if anc[1:] not in anchors:
                    errors.append(f'{key}: якорь {anc} не найден на {tgt_low} (есть: {sorted(anchors)[:8]}...)')
            continue
        m = re.match(r'https://bibleox\.com/ja/jp-ni/([a-z0-9]+)/(\d+)/#L(\d+(?:-\d+)?)$', href)
        if m:
            book, ch, vs = m.groups()
            first = vs.split('-')[0]
            addr = f'{book}:{ch}:{first}'
            if not verse_exists('jp-ni', addr):
                errors.append(f'{key}: нет стиха jp-ni {addr}')
            continue
        m = re.match(r'https://bibleox\.com/ja/jp-ni/([a-z0-9]+)/(\d+)/$', href)
        if m:
            book, ch = m.groups()
            n = sql(f"SELECT count(*) FROM verses WHERE tr_code='jp-ni' AND book='{book}' AND chapter={ch};")
            if n == '0':
                errors.append(f'{key}: нет главы jp-ni {book} {ch}')
            continue
        if href.startswith('https://bibleox.com') and '/w/' not in href:
            errors.append(f'{key}: неразобранная ссылка {href}')
        # внешние ссылки не проверяем
    print(f'{key}: {len(seen)} уникальных ссылок')

if errors:
    print('\nОШИБКИ:')
    for e in errors:
        print(' -', e)
    sys.exit(1)
print('\nВсе ссылки корректны.')
