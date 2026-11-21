#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Разбор ru-страницы Иустина (ru 389) на блоки: заголовки, проза, цитаты
со ссылками-источниками. Выделения внутри цитат нормализуются в «прогоны»:
максимальные участки с одинаковым набором тегов (strong/mark/em).
Выход: blocks.json
"""
import re, json, os

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'ru_389_bio.html')
JA_MAP = os.path.join(HERE, '..', '..', 'script', 'translations', 'justin-ja', 'quote_map.json')

SEP_RE = re.compile(r'^<p>&lt;…&gt;</p>$')
TAG_RE = re.compile(r'<(/?)(strong|mark|em)>')
ELEM_RE = re.compile(r'<(h2|h3|blockquote|p)(?:\s[^>]*)?>')
SOURCE_RE = re.compile(r'^\(<a href="([^"]+)"[^>]*>(.*?)</a>(.*?)\)$', re.S)


def inner_p(html):
    """Абзацы blockquote: список html-строк <p>..</p> (сепаратор помечен 'SEP')."""
    paras = re.findall(r'<p[^>]*>(.*?)</p>', html, re.S)
    out = []
    for p in paras:
        if p.strip() == '&lt;…&gt;':
            out.append('SEP')
        else:
            out.append(p)
    return out


def marked_runs(html):
    """[(text, frozenset(tags))] по абзацу цитаты (без <p>-обёртки)."""
    runs = []
    stack = []
    buf = []
    cur = None
    i = 0
    while i < len(html):
        m = TAG_RE.match(html, i)
        if m:
            is_close, name = m.group(1) == '/', m.group(2)
            if is_close:
                assert stack and stack[-1] == name, f'теги: {html[:80]}'
                stack.pop()
            else:
                stack.append(name)
            i = m.end()
            continue
        c = html[i]
        key = frozenset(stack)
        if cur is not None and key != cur:
            runs.append((''.join(buf), cur))
            buf = []
        cur = key
        buf.append(c)
        i += 1
    if buf:
        runs.append((''.join(buf), cur))
    # склейка соседних прогонов с одинаковым набором
    out = []
    for text, tags in runs:
        plain = re.sub(r'\s+', ' ', text)
        if not plain.strip():
            # пробелы: без собственного значения — приклеить к предыдущему
            if out:
                out[-1] = (out[-1][0] + plain, out[-1][1])
            else:
                out.append((plain, tags))
            continue
        if out and out[-1][1] == tags:
            out[-1] = (out[-1][0] + plain, tags)
        else:
            out.append((plain, tags))
    return out


NAME = {
    frozenset(): '',
    frozenset({'strong'}): 'b',
    frozenset({'mark'}): 'm',
    frozenset({'strong', 'mark'}): 'bm',
    frozenset({'em'}): 'e',
    frozenset({'em', 'strong'}): 'eb',
    frozenset({'em', 'mark'}): 'em',
    frozenset({'em', 'strong', 'mark'}): 'ebm',
}


def render_run(text, tags):
    n = NAME[tags]
    return f'<{n}>{text}</{n}>' if n else text


def marked_text(para_html):
    runs = marked_runs(para_html)
    return ''.join(render_run(t, tg) for t, tg in runs)


def parse():
    h = open(SRC, encoding='utf-8').read()
    ja = json.load(open(JA_MAP, encoding='utf-8'))  # [[0,[work,ch]], ...]
    ja_map = {i + 1: (v[0], v[1]) if v else None for i, v in ja}
    blocks = []
    pos = 0
    q = 0
    pending_quote = None
    bid = 0
    while True:
        m = ELEM_RE.search(h, pos)
        if not m:
            break
        tag = m.group(1)
        if tag in ('h2', 'h3'):
            end = h.index('</%s>' % tag, m.end())
            inner = h[m.end():end]
            bid += 1
            blocks.append({'id': bid, 'type': tag, 'html': inner})
            pos = end + len('</%s>' % tag)
        elif tag == 'blockquote':
            end = h.index('</blockquote>', m.end())
            inner = h[m.end():end]
            q += 1
            paras = inner_p(inner)
            groups, cur = [], []
            for p in paras:
                if p == 'SEP':
                    if cur:
                        groups.append(cur)
                    cur = []
                else:
                    cur.append(p)
            if cur:
                groups.append(cur)
            bid += 1
            annex = ja_map.get(q)
            blocks.append({
                'id': bid, 'type': 'quote', 'q': q,
                'groups': [[marked_text(p) for p in g] for g in groups],
                'annex': {'work': annex[0], 'chapter': annex[1]} if annex else None,
                'source': None,
            })
            pending_quote = blocks[-1]
            pos = end + len('</blockquote>')
        else:
            end = h.index('</p>', m.end())
            inner = h[m.end():end]
            sm = SOURCE_RE.match(inner.strip())
            bid += 1
            if sm and pending_quote is not None:
                pending_quote['source'] = {
                    'href': sm.group(1),
                    'title': sm.group(2),
                    'tail': sm.group(3),
                }
                pending_quote = None
                blocks.append({'id': bid, 'type': 'source', 'html': inner})
            else:
                blocks.append({'id': bid, 'type': 'p', 'html': inner})
            pos = end + len('</p>')
    return blocks


def main():
    blocks = parse()
    json.dump(blocks, open(os.path.join(HERE, 'blocks.json'), 'w', encoding='utf-8'),
              ensure_ascii=False, indent=1)
    from collections import Counter
    print(Counter(b['type'] for b in blocks))
    quotes = [b for b in blocks if b['type'] == 'quote']
    print('цитат:', len(quotes), 'со ссылкой:', sum(1 for b in quotes if b['source']))
    no_src = [b['q'] for b in quotes if not b['source']]
    print('без источника:', no_src)
    no_annex = [b['q'] for b in quotes if not b['annex']]
    print('без ja-главы:', no_annex)
    runs = sum(len(g) for b in quotes for g in b['groups'])
    print('групп (фрагментов):', sum(len(b['groups']) for b in quotes), 'абзацев:', runs)
    # ссылки в прозе
    for b in blocks:
        if b['type'] == 'p' and '<a' in b['html']:
            print('прозовая ссылка, блок', b['id'], re.findall(r'href="([^"]+)"', b['html']))


if __name__ == '__main__':
    main()
