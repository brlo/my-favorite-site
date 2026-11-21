#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Проверка ответов агентов (греческие цитаты): from/to, marks, структура."""
import json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
SEP = '<p>&lt;…&gt;</p>'
TOK = {'strong': ('strong',), 'b': ('strong',), 'mark': ('mark',), 'm': ('mark',),
       'bm': ('strong', 'mark'), 'e': ('em',),
       'eb': ('em', 'strong'), 'em': ('em', 'mark'), 'ebm': ('em', 'strong', 'mark')}
# для готового греческого текста <em> — просто курсив (в ru-разметке «em» = курсив+маркер)
TOK_GR = dict(TOK, em=('em',))


def plain_norm(s):
    return re.sub(r'\s+', '', re.sub(r'<[^>]+>', '', s))


def tag_counts(s, kind='gr'):
    c = {'strong': 0, 'mark': 0, 'em': 0}
    table = TOK_GR if kind == 'gr' else TOK
    for m in re.finditer(r'<(/?)(strong|mark|em|b|m|bm|e|eb|em|ebm)>', s):
        if m.group(1) == '/':
            continue
        for k in table.get(m.group(2), ()):
            c[k] += 1
    return c


def ru_counts(block):
    c = {'strong': 0, 'mark': 0, 'em': 0}
    for g in block['groups']:
        for p in g:
            cc = tag_counts(p, kind='ru')
            for k in c:
                c[k] += cc[k]
    return c


def cut(works, w, ch, frm, to):
    paras = works.get(w, {}).get(str(ch))
    if not paras:
        return None, 'нет главы'
    text = ' '.join(paras)
    i = text.find(frm)
    if i < 0:
        return None, f'from не найдено: {frm[:40]!r}'
    j = text.find(to, i)
    if j < 0:
        return None, f'to не найдено после from: {to[:40]!r}'
    return text[i:j + len(to)], None


def apply_marks(t, marks, where):
    out = t
    for mk in marks:
        tag, ph = mk[0], mk[1]
        nth = mk[2] if len(mk) > 2 else 0
        idxs = []
        at = out.find(ph)
        while at >= 0:
            idxs.append(at)
            at = out.find(ph, at + 1)
        if len(idxs) <= nth:
            raise SystemExit(f'{where}: фраза {ph[:40]!r} встречается {len(idxs)}, нужен #{nth+1}')
        s = idxs[nth]
        out = out[:s] + f'<{tag}>' + ph + f'</{tag}>' + out[s + len(ph):]
    return out


def main(chunk):
    blocks = json.load(open(os.path.join(HERE, 'blocks.json'), encoding='utf-8'))
    works = json.load(open(os.path.join(HERE, 'works.json'), encoding='utf-8'))
    out = json.load(open(os.path.join(HERE, 'out', chunk + '.json'), encoding='utf-8'))
    byid = {b['id']: b for b in blocks}
    bad = 0
    for bid_s, val in sorted(out.items(), key=lambda kv: int(kv[0])):
        b = byid[int(bid_s)]
        ru_paras = [p for g in b['groups'] for p in g]
        specs = val['paras']
        status = []
        if len(specs) != len(ru_paras):
            status.append(f'АБЗАЦЕВ {len(specs)} вместо {len(ru_paras)}')
        rc = ru_counts(b)
        ec = {'strong': 0, 'mark': 0, 'em': 0}
        texts = []
        for spec in specs:
            if spec.get('own'):
                t = spec.get('text', '')
                texts.append(t)
                for k in ec:
                    ec[k] += tag_counts(t)[k]
                continue
            t, err = cut(works, spec['w'], spec['ch'], spec['from'], spec['to'])
            if err:
                status.append(err)
                continue
            try:
                t = apply_marks(t, spec.get('marks', []), f'Q{b["q"]}')
            except SystemExit as e:
                status.append(str(e))
                continue
            texts.append(t)
            for k in ec:
                ec[k] += tag_counts(t)[k]
        cyr = re.findall(r'[А-Яа-яЁё]', ''.join(texts))
        if cyr:
            status.append('КИРИЛЛИЦА')
        if rc != ec:
            status.append(f'ВЫДЕЛЕНИЯ ru={rc} en={ec}')
        if status:
            bad += 1
        print(('!! ' if status else 'OK ') + f'Q{b["q"]:<3} B{b["id"]:<4} {val.get("where",""):<12} ' + '; '.join(status))
    print(f'\nпроблемных цитат: {bad} из {len(out)}')


if __name__ == '__main__':
    main(sys.argv[1])
