#!/usr/bin/env python3
"""Подготовка данных для перевода страницы Иринея Лионского на en/grc.

- разбор RU-эталона (457) на блоки;
- поиск каждой цитаты в русских трудах (458-463, 459, 608) -> книга/глава/абзац;
- выгрузка целевых глав: en (ANF), la, grc;
- сборка JSON-карт.
"""
import json
import os
import re
import sys
import unicodedata

from lxml import html as LH

HERE = os.path.dirname(os.path.abspath(__file__))
TMP = os.environ.get('IREN_TMP') or HERE
DB = os.path.join(TMP, 'db')


def load_body(page_id):
    with open(os.path.join(DB, f'{page_id}.html'), encoding='utf-8') as f:
        return f.read()


def parse_page(page_id):
    """Вернуть список глав: {title, anchor, paras:[html]} по <h2>."""
    body = load_body(page_id)
    doc = LH.fromstring('<div>' + body + '</div>')
    root = doc.xpath('//div')[0]
    chapters = []
    preface = {'title': None, 'anchor': None, 'paras': []}
    cur = preface
    counters = {}

    def anchor_of(title):
        t = re.sub(r'[^0-9A-Za-z\u00c0-\u024f\u0370-\u03ff\u1f00-\u1fff\s\-]', '', title)
        t = t.replace(' ', '-')
        idx = counters[t] = counters.get(t, 0) + 1
        return ('HH' + (str(idx) if idx > 1 else '') + '-' + t)

    for el in root:
        if el.tag in ('h2',):
            title = el.text_content().strip()
            cur = {'title': title, 'anchor': anchor_of(title), 'paras': []}
            chapters.append(cur)
        elif el.tag in ('p', 'blockquote', 'li'):
            cur['paras'].append(LH.tostring(el, encoding='unicode'))
        elif el.tag in ('ul', 'ol'):
            for li in el.xpath('.//li'):
                cur['paras'].append(LH.tostring(li, encoding='unicode'))
    if preface['paras']:
        chapters.insert(0, preface)
    return chapters


# --- RU-эталон -------------------------------------------------------------

def parse_ru_blocks():
    chapters = parse_page(457)  # у страницы автора только один "раздел" (нет h2 в корне? нет, есть)
    # Для страницы автора: идём по исходному html напрямую, сохраняя h2/h3/p/blockquote
    body = load_body(457)
    doc = LH.fromstring('<div>' + body + '</div>')
    root = doc.xpath('//div')[0]
    blocks = []
    cur2 = cur3 = None
    for el in root:
        if el.tag == 'h2':
            cur2 = el.text_content().strip()
            cur3 = None
            blocks.append({'k': 'h2', 't': cur2, 'html': LH.tostring(el, encoding='unicode')})
        elif el.tag == 'h3':
            cur3 = el.text_content().strip()
            blocks.append({'k': 'h3', 't': cur3, 'html': LH.tostring(el, encoding='unicode')})
        elif el.tag == 'blockquote':
            txt = el.text_content()
            marks = extract_marks(el)
            blocks.append({'k': 'quote', 'html': LH.tostring(el, encoding='unicode'),
                           'text': txt, 'marks': marks})
        elif el.tag in ('p',):
            blocks.append({'k': 'p', 'html': LH.tostring(el, encoding='unicode'),
                           'text': el.text_content()})
        elif el.tag in ('ul', 'ol'):
            blocks.append({'k': el.tag, 'html': LH.tostring(el, encoding='unicode'),
                           'text': el.text_content()})
        elif el.tag == 'hr':
            blocks.append({'k': 'hr', 'html': '<hr>'})
    for n, b in enumerate(blocks):
        b['id'] = n
        b['h2'] = ''
        b['h3'] = ''
    cur2 = cur3 = ''
    for b in blocks:
        if b['k'] == 'h2':
            cur2 = b['t']
            cur3 = ''
        elif b['k'] == 'h3':
            cur3 = b['t']
        b['h2'] = cur2
        b['h3'] = cur3
    return blocks


MARK_TAGS = ('strong', 'em', 'mark', 'u')


def extract_marks(bq):
    """Выделения цитаты: [tag, phrase] или [tag, 'WHOLE'] (непрерывные куски)."""
    chars = []  # (char, frozenset(tags))

    def walk(node, active):
        if node.text:
            for ch in node.text:
                chars.append((ch, active))
        for child in node:
            tag = child.tag if isinstance(child.tag, str) else ''
            act = active | {tag} if tag in MARK_TAGS else active
            walk(child, act)
            if child.tail:
                for ch in child.tail:
                    chars.append((ch, active))

    walk(bq, frozenset())
    whole = ''.join(c for c, _ in chars)
    stripped_len = len(whole.strip())
    out = []
    for tag in MARK_TAGS:
        runs = []
        cur = None
        for i, (c, tags) in enumerate(chars):
            if tag in tags:
                if cur is None:
                    cur = [i, i + 1]
                else:
                    cur[1] = i + 1
            else:
                if cur:
                    runs.append(cur)
                    cur = None
        if cur:
            runs.append(cur)
        if not runs:
            continue
        total = sum(b - a for a, b in runs)
        if stripped_len and total >= 0.9 * stripped_len:
            out.append([tag, 'WHOLE'])
            continue
        for a, b in runs:
            phrase = whole[a:b]
            if not phrase.strip():
                continue
            cnt = whole.count(phrase)
            if cnt > 1:
                order = [m for m in out if m[1] == phrase]
                out.append([tag, phrase, len(order) + 1])
            else:
                out.append([tag, phrase])
    return out


def norm(s):
    s = re.sub(r'<[^>]+>', ' ', s)
    s = s.replace('ё', 'е').replace('Ё', 'Е').lower()
    s = unicodedata.normalize('NFKC', s)
    s = re.sub(r'[^0-9a-z\u0430-\u044f]+', ' ', s)
    return ' '.join(s.split())


# --- русские труды: для локализации цитат --------------------------------

RU_WORKS = {1: 458, 2: 460, 3: 461, 4: 462, 5: 463, 'dem': 459, 'frag': 608}


def load_ru_works():
    works = {}
    for key, page_id in RU_WORKS.items():
        chapters = parse_page(page_id)
        out = []
        for ch in chapters:
            title = ch['title'] or ''
            m = re.match(r'^\s*(\d+)', title)
            num = int(m.group(1)) if m else None
            paras = [{'plain': norm(p), 'html': p} for p in ch['paras']]
            out.append({'num': num, 'title': title, 'anchor': ch['anchor'], 'paras': paras})
        works[str(key)] = out
    return works


def shingles(text, n=5):
    w = text.split()
    return {' '.join(w[i:i + n]) for i in range(0, max(0, len(w) - n + 1))}


def locate_quote(works, quote_text, restrict=None):
    """Найти (work, chapter, para, coverage) по нормализованному тексту."""
    import difflib
    q = norm(quote_text)
    if len(q) < 20:
        return None
    qs = shingles(q, 4)
    best = (0, None, None, None, None)
    keys = [restrict] if restrict else list(works.keys())
    for key in keys:
        for ch in works[key]:
            if ch['num'] is None:
                continue
            paras = ch['paras']
            for pi in range(len(paras)):
                acc = ''
                for span in range(1, 6):
                    if pi + span > len(paras):
                        break
                    acc = (acc + ' ' + paras[pi + span - 1]['plain']).strip()
                    ps = shingles(acc, 4)
                    if not qs or len(qs & ps) < max(1, len(qs) // 3):
                        continue
                    sm = difflib.SequenceMatcher(None, acc, q, autojunk=False)
                    cov = sum(b.size for b in sm.get_matching_blocks()) / max(1, len(q))
                    if cov > best[0]:
                        best = (cov, key, ch['num'], pi, span)
    if best[0] < 0.5:
        return None
    return {'coverage': round(best[0], 3), 'work': best[1], 'chapter': best[2],
            'para': best[3], 'span': best[4]}


def main():
    blocks = parse_ru_blocks()
    works = load_ru_works()
    quotes = []
    for b in blocks:
        if b['k'] != 'quote':
            continue
        loc = locate_quote(works, b['text'])
        quotes.append({'block': b['id'], 'text': b['text'][:120], 'loc': loc})
    json.dump(blocks, open(os.path.join(TMP, 'blocks.json'), 'w'), ensure_ascii=False, indent=1)
    json.dump(quotes, open(os.path.join(TMP, 'quote_locs.json'), 'w'), ensure_ascii=False, indent=1)
    found = [q for q in quotes if q['loc']]
    print(f'blocks: {len(blocks)}, quotes: {len(quotes)}, located: {len(found)}')
    for q in quotes:
        if not q['loc']:
            print('NOT FOUND', q['block'], q['text'][:80])


if __name__ == '__main__':
    main()
