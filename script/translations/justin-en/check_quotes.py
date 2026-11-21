#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Проверка ответов агентов: структура цитат, дословность в тексте труда, выделения."""
import json, os, re, sys, html

HERE = os.path.dirname(os.path.abspath(__file__))
WORKS = {'A1': 'en_ap1.html', 'A2': 'en_ap2.html', 'Dial': 'en_dial.html'}
SEP = '<p>&lt;…&gt;</p>'
TAGS = re.compile(r'<(/?)(strong|mark|em|b|m|bm|e|eb|em|ebm)>')


def plain_norm(s):
    """Плоский текст: без тегов, без сносок [n], без пробелов."""
    s = re.sub(r'<[^>]+>', '', s)
    s = html.unescape(s)
    s = re.sub(r'\[\d+\]', '', s)
    return re.sub(r'\s+', '', s)


_work_cache = {}


def work_text(w):
    if w not in _work_cache:
        h = open(os.path.join(HERE, WORKS[w]), encoding='utf-8').read()
        parts = re.split(r'<h2[^>]*>(.*?)</h2>', h)
        chaps = []
        for i in range(1, len(parts), 2):
            chaps.append((parts[i].strip(), plain_norm(parts[i + 1])))
        _work_cache[w] = chaps
    return _work_cache[w]


def find_chapter(w, text):
    best, bestn = None, 0
    for name, body in work_text(w):
        if text in body:
            # длина главы как tie-break
            return name
        n = len(body)
        if n > bestn:
            best, bestn = name, n
    return None


TOK = {
    'strong': ('strong',), 'b': ('strong',),
    'mark': ('mark',), 'm': ('mark',),
    'bm': ('strong', 'mark'),
    'e': ('em',),
    'eb': ('em', 'strong'),
    'em': ('em', 'mark'),
    'ebm': ('em', 'strong', 'mark'),
}


EN_TOK = {
    'strong': ('strong',), 'mark': ('mark',), 'em': ('em',),
    'b': ('strong',), 'm': ('mark',), 'bm': ('strong', 'mark'),
    'e': ('em',), 'eb': ('em', 'strong'), 'ebm': ('em', 'strong', 'mark'),
}


def tag_counts(s, kind='en'):
    c = {'strong': 0, 'mark': 0, 'em': 0}
    table = EN_TOK if kind == 'en' else TOK
    for m in TAGS.finditer(s):
        if m.group(1) == '/':
            continue
        for k in table.get(m.group(2), ()):
            c[k] += 1
    return c


def ru_tag_counts(block):
    c = {'strong': 0, 'mark': 0, 'em': 0}
    for g in block['groups']:
        for p in g:
            cc = tag_counts(p, kind='ru')
            for k in c:
                c[k] += cc[k]
    return c


def main(chunk):
    blocks = json.load(open(os.path.join(HERE, 'blocks.json'), encoding='utf-8'))
    byid = {b['id']: b for b in blocks}
    out = json.load(open(os.path.join(HERE, 'out', chunk + '.json'), encoding='utf-8'))
    bad = 0
    for bid_s, val in sorted(out.items(), key=lambda kv: int(kv[0])):
        bid = int(bid_s)
        b = byid[bid]
        assert b['type'] == 'quote', f'B{bid} не цитата'
        paras = val['quote']
        own = set(val.get('own', []))
        # структура
        groups_ru = b['groups']
        groups_en, cur = [], []
        for p in paras:
            if p == SEP:
                groups_en.append(cur)
                cur = []
            else:
                cur.append(p)
        groups_en.append(cur)
        struct_ok = ([len(g) for g in groups_ru] == [len(g) for g in groups_en])
        cyr = re.findall(r'[А-Яа-яЁё]', ''.join(paras))
        # дословность по абзацам
        flat_idx = 0
        missed = []
        chapters = []
        for gi, g in enumerate(groups_en):
            for p in g:
                if flat_idx in own:
                    flat_idx += 1
                    continue
                t = plain_norm(p)
                works = val.get('where', '').split(',')
                cand = []
                for w in WORKS:
                    ch = find_chapter(w, t)
                    if not ch:
                        # известная опечатка ANF: «eternal punishment by tire»
                        ch = find_chapter(w, t.replace('byfire', 'bytire'))
                        if ch:
                            ch += ' (опечатка tire/fire)'
                    if ch:
                        cand.append(f'{w} {ch}')
                if not cand:
                    missed.append(flat_idx)
                else:
                    chapters.append(cand[0])
                flat_idx += 1
        tc_ru = ru_tag_counts(b)
        tc_en = tag_counts(''.join(paras))
        status = []
        if not struct_ok:
            status.append('СТРУКТУРА')
        if missed:
            status.append('НЕ НАЙДЕНО %s' % missed)
        if cyr:
            status.append('КИРИЛЛИЦА')
        diff = {k: (tc_ru[k], tc_en[k]) for k in tc_ru if tc_ru[k] != tc_en[k]}
        if diff:
            status.append('ВЫДЕЛЕНИЯ ru/en %s' % diff)
        flag = 'OK ' if not status else '!! '
        if status:
            bad += 1
        print(f'{flag}Q{b["q"]:<3} B{bid:<4} {val.get("where",""):<14} '
              f'{chapters[0] if chapters else "-":<10} {" ".join(status)}')
    print('\nпроблемных цитат:', bad, 'из', len(out))
    unknown = set(out) - {str(b['id']) for b in blocks if b['type'] == 'quote'}
    if unknown:
        print('лишние ключи:', unknown)


if __name__ == '__main__':
    main(sys.argv[1])
