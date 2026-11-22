#!/usr/bin/env python3
"""Проверка EN-страницы Климента Римского (ru 418 -> en 423).

Читает уже импортированную страницу из dev-базы и проверяет:
  * дословность каждой цитаты по английскому переводу 1-го послания (страница ClemRm_Kor1)
    и по «Против ересей» III (irenaeus-against-heresies-b3); «…» внутри цитаты — пропуск;
  * парность HTML-тегов и отсутствие кириллицы в body и references;
  * что сноскам [n] в тексте соответствуют n пунктов <ol> в references;
  * что все ссылки и анкоры живы (страницы в базе, анкоры — на отрендеренной странице,
    стихи — на странице Библии).

Запуск (в контейнере, из /app):
    bin/rails runner script/translations/clement-en/check_page.py   # нет, это python
    python3 script/translations/clement-en/check_page.py [--site URL] [--db КОНТЕЙНЕР]

Скрипт хостовый: ходит в контейнеры docker exec и на сайт curl-ом.
"""
import argparse
import html
import re
import subprocess
import sys
import urllib.parse
from html.parser import HTMLParser

# явные опечатки электронного текста ANF, исправленные в цитатах (см. references)
FIXUPS = [
    ('command-merits', 'commandments'),
    ('neighhours', 'neighbours'),
    ('furnished. us', 'furnished us'),
    ('than to receive? Content', 'than to receive. Content'),
    ('bishops s in righteousness', 'bishops in righteousness'),
    ('and there would be strife', 'that there would be strife'),
    ('blame-lessly', 'blamelessly'),
    ('preserved in, Christ Jesus', 'preserved in Christ Jesus'),
    ('fixed by faith rewards God', 'fixed by faith towards God'),
    ('[has done sol from God', '[has done so] from God'),
    ('sin- offerings', 'sin-offerings'),
]

AUTHOR = 'clement_of_rome'
EPISTLE = 'clemrm_kor1'
IRENAEUS = 'irenaeus-against-heresies-b3'
BIBLE_PREFIX = '/en/eng-nkjv/'


def psql(db, sql):
    out = subprocess.run(
        ['docker', 'exec', db, 'psql', '-U', 'bibleox', 'bibleox_development', '-t', '-A', '-c', sql],
        capture_output=True, text=True)
    if out.returncode:
        sys.exit(f'psql: {out.stderr.strip()}')
    return out.stdout.strip()


def page_body(db, path):
    return psql(db, f"SELECT body FROM pages WHERE lang='en' AND path_low='{path}'")


def plain(fragment):
    text = re.sub(r'<[^>]+>', '', fragment)
    text = html.unescape(text).replace('\u00a0', ' ')
    text = re.sub(r'\[[0-9]+\]', '', text)  # маркеры сносок не часть текста
    return re.sub(r'\s+', ' ', text).strip()


def chapters(raw, fixups=()):
    parts = re.split(r'(<h2[^>]*>.*?</h2>)', raw)
    result = {}
    for i in range(1, len(parts), 2):
        num = plain(parts[i])
        paragraphs = re.findall(r'<p>(.*?)</p>', parts[i + 1], re.S)
        text = ' '.join(plain(p) for p in paragraphs)
        for old, new in fixups:
            text = text.replace(old, new)
        result[num] = re.sub(r'\s+', ' ', text).strip()
    return result


class Balance(HTMLParser):
    VOID = {'br', 'hr', 'img'}

    def __init__(self):
        super().__init__()
        self.stack = []
        self.errors = []

    def handle_starttag(self, tag, attrs):
        if tag not in self.VOID:
            self.stack.append(tag)

    def handle_endtag(self, tag):
        if not self.stack:
            self.errors.append(f'лишний </{tag}>')
        elif self.stack[-1] != tag:
            self.errors.append(f'</{tag}> закрывает <{self.stack[-1]}>')
        else:
            self.stack.pop()


def check_quotes(body, epistle, irenaeus, errors):
    checked = 0
    for match in re.finditer(r'<blockquote>(.*?)</blockquote>', body, re.S):
        quote = match.group(1)
        after = body[match.end():match.end() + 4000]
        source = re.match(r'\s*<p>\((.*?)\)</p>', after, re.S)
        if not source:
            if 'Rom. 12:16' in quote:
                continue
            errors.append(f'цитата без строки-источника: {plain(quote)[:80]}')
            continue
        nums, pool = [], {}
        for href in re.findall(r'href="([^"]+)"', source.group(1)):
            found = re.search(r'#HH-([0-9]+)$', href)
            if not found:
                continue
            num = found.group(1)
            table = irenaeus if 'irenaeus' in href else epistle
            if num not in table:
                errors.append(f'нет главы {num} в источнике {href}')
                continue
            nums.append(num)
            pool[num] = table[num]
        if not nums:
            errors.append(f'источник без номера главы: {plain(source.group(1))[:80]}')
            continue
        last = -1
        for para in re.findall(r'<p>(.*?)</p>', quote, re.S):
            text = plain(para)
            if not text or set(text) <= set('…. '):
                continue
            for segment in re.split(r'…|<…>', text):
                segment = segment.strip()
                if not segment:
                    continue
                hits = [n for n in nums if segment in pool[n] or segment.rstrip('.,;:') in pool[n]]
                if not hits:
                    errors.append(f'НЕ НАЙДЕНО в главах {nums}: {segment[:120]!r}')
                else:
                    idx = nums.index(hits[0])
                    if idx < last:
                        errors.append(f'порядок глав нарушен: {nums}, {segment[:60]!r}')
                    last = idx
                checked += 1
    return checked


def fetch(site, url):
    return subprocess.run(['curl', '-s', '-L', url], capture_output=True, text=True).stdout


def check_links(site, db, html_text, errors):
    links = sorted(set(re.findall(r'href="([^"]+)"', html_text)))
    for link in links:
        parsed = urllib.parse.urlparse(link)
        if parsed.netloc != 'bibleox.com':
            errors.append(f'внешний домен: {link}')
            continue
        path = urllib.parse.unquote(parsed.path)
        parts = [p for p in path.split('/') if p]
        if len(parts) >= 2 and parts[1] == 'eng-nkjv':
            page = fetch(site, f'{site}/en/{parts[1]}/{parts[2]}/{parts[3]}/')
            if not page:
                errors.append(f'нет страницы Библии: {link}')
            elif parsed.fragment and f"id='{parsed.fragment}'" not in page and f'id="{parsed.fragment}"' not in page:
                errors.append(f'нет стиха {parsed.fragment}: {link}')
            continue
        if len(parts) == 4 and parts[2] == 'w':
            ui, lang, slug = parts[0], parts[1], parts[3]
            exists = psql(db, f"SELECT 1 FROM pages WHERE lang='{lang}' AND path_low=lower('{slug.replace(chr(39), chr(39) * 2)}')")
            if not exists:
                errors.append(f'нет страницы {lang}:{slug}: {link}')
                continue
            anchor = parsed.fragment
            if anchor.startswith('HH-'):
                page = fetch(site, f'{site}/{ui}/{lang}/w/{urllib.parse.quote(slug)}')
                if f'id="{anchor}"' not in page and f"id='{anchor}'" not in page:
                    errors.append(f'нет анкора {anchor}: {link}')
            continue
        errors.append(f'неизвестный тип ссылки: {link}')
    return len(links)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--site', default='http://localhost')
    parser.add_argument('--db', default='bibpostgres')
    args = parser.parse_args()

    body = page_body(args.db, AUTHOR)
    if not body:
        sys.exit('нет страницы en:' + AUTHOR)
    references = psql(args.db, f"SELECT \"references\" FROM pages WHERE lang='en' AND path_low='{AUTHOR}'")
    epistle = chapters(page_body(args.db, EPISTLE), FIXUPS)
    irenaeus = chapters(page_body(args.db, IRENAEUS))

    errors = []
    balance = Balance()
    balance.feed(body)
    errors += [f'незакрытые теги: {balance.stack}'] if balance.stack else []
    errors += balance.errors
    for name, text in (('body', body), ('references', references)):
        if re.search(r'[А-Яа-яЁё]', text):
            errors.append(f'кириллица в {name}')

    visible = html.unescape(re.sub(r'<[^>]+>', '', body))
    marks = re.findall(r'\[([0-9]+)\]', visible)
    notes = len(re.findall(r'<li>', references))
    if len(marks) != notes:
        errors.append(f'сносок в тексте {len(marks)}, пунктов в references {notes}')

    checked = check_quotes(body, epistle, irenaeus, errors)
    links = check_links(args.site, args.db, body + references, errors)

    print(f'фрагментов цитат проверено: {checked}')
    print(f'ссылок проверено: {links}')
    print(f'сносок: {len(marks)}, пунктов references: {notes}')
    for error in sorted(set(errors)):
        print('ОШИБКА:', error)
    print('ИТОГО ошибок:', len(set(errors)))
    return 1 if errors else 0


if __name__ == '__main__':
    sys.exit(main())
