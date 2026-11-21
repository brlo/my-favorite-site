#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Разбор ru-страницы на блоки (без привязки к ja-разметке): h2/h3/h4, blockquote
с абзацами и спанами выделений, строки-источники, проза, таблицы.
Использование: parse_ru.py <ru.html> <out.json>
"""
import re, json, sys, os

SEP_RE = re.compile(r'^<p>&lt;…&gt;</p>$')
TAG_RE = re.compile(r'<(/?)(strong|mark|em|u)>')
ELEM_RE = re.compile(r'<(h2|h3|h4|blockquote|p|table)(?:\s[^>]*)?>')
SOURCE_RE = re.compile(r'^\(<a href="([^"]+)"[^>]*>(.*?)</a>(.*?)\)$', re.S)
LETTERS = (('strong', 'b'), ('mark', 'm'), ('em', 'e'), ('u', 'u'))


def name_of(tags):
    return ''.join(l for t, l in LETTERS if t in tags)


NAME = type('N', (dict,), {'__missing__': lambda self, k: name_of(k)})()


def inner_p(html):
    out = []
    for p in re.findall(r'<p[^>]*>(.*?)</p>', html, re.S):
        out.append('SEP' if p.strip() == '&lt;…&gt;' else p)
    return out


def marked_runs(html):
    runs, stack, buf, cur, i = [], [], [], None, 0
    while i < len(html):
        m = TAG_RE.match(html, i)
        if m:
            is_close, name = m.group(1) == '/', m.group(2)
            if is_close:
                for k in range(len(stack) - 1, -1, -1):
                    if stack[k] == name:
                        stack.pop(k)
                        break
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
    out = []
    for text, tags in runs:
        plain = re.sub(r'\s+', ' ', text)
        if not plain.strip():
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


def marked_text(para_html):
    s = []
    for text, tags in marked_runs(para_html):
        n = NAME[tags]
        s.append(f'<{n}>{text}</{n}>' if n else text)
    return ''.join(s)


def parse(src):
    h = open(src, encoding='utf-8').read()
    blocks, pos, q, bid = [], 0, 0, 0
    pending = None
    while True:
        m = ELEM_RE.search(h, pos)
        if not m:
            break
        tag = m.group(1)
        if tag in ('h2', 'h3', 'h4'):
            end = h.index('</%s>' % tag, m.end())
            bid += 1
            blocks.append({'id': bid, 'type': tag, 'html': h[m.end():end]})
            pos = end + len('</%s>' % tag)
        elif tag == 'table':
            end = h.index('</table>', m.end())
            bid += 1
            blocks.append({'id': bid, 'type': 'table', 'html': h[m.start():end + len('</table>')]})
            pos = end + len('</table>')
        elif tag == 'blockquote':
            end = h.index('</blockquote>', m.end())
            q += 1
            paras = inner_p(h[m.end():end])
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
            blocks.append({'id': bid, 'type': 'quote', 'q': q,
                           'groups': [[marked_text(p) for p in g] for g in groups],
                           'source': None})
            pending = blocks[-1]
            pos = end + len('</blockquote>')
        else:
            end = h.index('</p>', m.end())
            inner = h[m.end():end]
            bid += 1
            sm = SOURCE_RE.match(inner.strip())
            if sm and pending is not None:
                pending['source'] = {'href': sm.group(1), 'title': sm.group(2),
                                     'tail': sm.group(3)}
                pending = None
                blocks.append({'id': bid, 'type': 'source', 'html': inner})
            else:
                blocks.append({'id': bid, 'type': 'p', 'html': inner})
            pos = end + len('</p>')
    return blocks


def main():
    src, out = sys.argv[1], sys.argv[2]
    blocks = parse(src)
    json.dump(blocks, open(out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    from collections import Counter
    c = Counter(b['type'] for b in blocks)
    print(out, dict(c))
    quotes = [b for b in blocks if b['type'] == 'quote']
    print('цитат:', len(quotes), 'со ссылкой:', sum(1 for b in quotes if b['source']))
    print('без ссылки:', [b['q'] for b in quotes if not b['source']])


if __name__ == '__main__':
    main()
