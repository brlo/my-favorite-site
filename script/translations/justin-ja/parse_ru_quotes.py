#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Парсер ru-авторской страницы Иустина (ru_389_bio.html): 101 blockquote,
# композитные фрагменты (разделитель <p>&lt;…&gt;</p>), спаны выделений
# (strong/mark/em) с plain-позициями. Результат: ru_quotes.json
import re, json, os

HERE = os.path.dirname(os.path.abspath(__file__))
HTML = os.path.join(HERE, 'ru_389_bio.html')
SEP = '<p>&lt;…&gt;</p>'

def strip_ws(t):
    return re.sub(r'\s+', '', t)

def readable(t):
    return re.sub(r'\s+', ' ', t).strip()

def group_plain_paras(paras):
    return strip_ws(re.sub(r'\[\d+\]', '', re.sub(r'<[^>]+>', '', ''.join(paras))))

def char_map(html):
    # [(start, end)] в html-координатах для каждого видимого символа (после
    # выкидывания тегов, \s и маркеров сносок [n]) — как plain()
    foot = re.compile(r'\[\d+\]')
    mapping = []
    i = 0
    n = len(html)
    while i < n:
        c = html[i]
        if c == '<':
            j = html.find('>', i)
            i = (j + 1) if j >= 0 else n
            continue
        if c.isspace():
            i += 1
            continue
        m = foot.match(html, i)
        if m:
            i = m.end()
            continue
        mapping.append((i, i + 1))
        i += 1
    return mapping

def extract_spans(html):
    # спаны (tag, s, e, text) по plain-координатам группы; сильные/марк/ем,
    # корректная вложенность гарантируется исходным HTML
    mapping = char_map(html)
    opens = []   # стек открытых тегов: [tag, plain_start]
    spans = []
    i = 0
    n = len(html)
    pos = 0  # текущая plain-позиция
    while i < n:
        c = html[i]
        if c == '<':
            j = html.find('>', i)
            tag_html = html[i:j+1] if j >= 0 else html[i:]
            m = re.match(r'<(/?)([a-zA-Z0-9]+)', tag_html)
            if m:
                closing, name = m.group(1) == '/', m.group(2)
                if not closing and name in ('strong', 'mark', 'em'):
                    opens.append([name, pos])
                elif closing and name in ('strong', 'mark', 'em'):
                    for k in range(len(opens) - 1, -1, -1):
                        if opens[k][0] == name:
                            t, s = opens.pop(k)
                            if pos > s:
                                spans.append({'tag': t, 's': s, 'e': pos})
                            break
            i = (j + 1) if j >= 0 else n
            continue
        if c.isspace():
            i += 1
            continue
        m = re.match(r'\[\d+\]', html[i:])
        if m:
            i += m.end()
            continue
        pos += 1
        i += 1
    assert not opens, f'незакрытые теги: {opens}'
    spans.sort(key=lambda x: (x['s'], x['e']))
    # текст спана по plain-карте
    for sp in spans:
        a = mapping[sp['s']][0]
        b = mapping[sp['e'] - 1][1]
        raw = html[a:b]
        sp['text'] = readable(re.sub(r'<[^>]+>', '', raw))
        sp['stext'] = sp['text'][:20]
        sp['etext'] = sp['text'][-20:]
    return spans

def parse():
    html = open(HTML, encoding='utf-8').read()
    bqs = re.findall(r'<blockquote>(.*?)</blockquote>', html, flags=re.S)
    assert len(bqs) == 101, len(bqs)
    out = {}
    for n0, b in enumerate(bqs, start=1):
        paras = re.findall(r'<p[ >].*?</p>', b, flags=re.S)
        groups, cur = [], []
        for p in paras:
            if p == SEP:
                if cur:
                    groups.append(cur); cur = []
            else:
                cur.append(p)
        if cur:
            groups.append(cur)
        gs = []
        for paras_g in groups:
            joined = ''.join(paras_g)
            gs.append({
                'plain': group_plain_paras(paras_g),
                'text': readable(re.sub(r'<[^>]+>', '', re.sub(r'\[\d+\]', '', joined))),
                'spans': extract_spans(joined),
            })
        out[str(n0)] = gs
    return out

def stats(data):
    tot = {'strong': 0, 'mark': 0, 'em': 0}
    for n, gs in data.items():
        for g in gs:
            for sp in g['spans']:
                tot[sp['tag']] += 1
    print('спаны внутри цитат:', tot, 'сумма:', sum(tot.values()))
    # паттерны вложенности
    pat = {}
    for n, gs in data.items():
        for g in gs:
            sps = g['spans']
            for i, a in enumerate(sps):
                for b in sps[i+1:]:
                    if b['s'] >= a['e']:
                        break
                    key = f"{a['tag']}>{b['tag']}" if (a['s'] <= b['s'] and b['e'] <= a['e']) else 'CROSS'
                    pat[key] = pat.get(key, 0) + 1
    print('вложенность:', pat)
    # спаны вне цитат (по всему html)
    html = open(HTML, encoding='utf-8').read()
    no_bq = re.sub(r'<blockquote>.*?</blockquote>', '', html, flags=re.S)
    print('теги вне цитат:', {t: len(re.findall(f'<{t}[ >]', no_bq)) for t in ('strong', 'mark', 'em')})

if __name__ == '__main__':
    data = parse()
    out = os.path.join(HERE, 'ru_quotes.json')
    json.dump(data, open(out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('OK ->', out)
    stats(data)
