#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Сборка греческой страницы автора: blocks + parts + works -> body.html.
Использование: build_page.py <page>  (page = ign | pol)
"""
import json, os, re, glob, sys, html as _html

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
SEP = '<p>&lt;…&gt;</p>'

META = {
    'ign': {
        'blocks': 'blocks_ign.json', 'parts': 'ign_parts', 'out': 'ign_body.html',
        'works': {
            'Ef': ('https://bibleox.com/grc/grc/w/%CE%99%CE%B3%CE%BD%CE%98_%CE%95%CF%86', 'Πρὸς Ἐφεσίους'),
            'Mag': ('https://bibleox.com/grc/grc/w/%CE%99%CE%B3%CE%BD%CE%98_%CE%9C%CE%B1%CE%B3', 'Πρὸς Μαγνησιεῖς'),
            'Tral': ('https://bibleox.com/grc/grc/w/%CE%99%CE%B3%CE%BD%CE%98_%CE%A4%CF%81%CE%B1%CE%BB', 'Πρὸς Τραλλιανούς'),
            'Rom': ('https://bibleox.com/grc/grc/w/%CE%99%CE%B3%CE%BD%CE%98_%CE%A1%CF%89%CE%BC', 'Πρὸς Ῥωμαίους'),
            'Phil': ('https://bibleox.com/grc/grc/w/%CE%99%CE%B3%CE%BD%CE%98_%CE%A6%CE%B9%CE%BB', 'Πρὸς Φιλαδελφεῖς'),
            'Smyr': ('https://bibleox.com/grc/grc/w/%CE%99%CE%B3%CE%BD%CE%98_%CE%A3%CE%BC', 'Πρὸς Σμυρναίους'),
            'Pol': ('https://bibleox.com/grc/grc/w/%CE%99%CE%B3%CE%BD%CE%98_%CE%A0%CE%BF%CE%BB', 'Πρὸς Πολύκαρπον'),
            'PlkFl': ('https://bibleox.com/grc/grc/w/%CE%95%CF%80%CE%B9%CF%83%CF%84%CE%BF%CE%BB%CE%AE-%CE%A0%CE%BF%CE%BB%CF%85%CE%BA%CE%AC%CF%81%CF%80%CE%BF%CF%85-%CF%80%CF%81%CE%BF%CF%82-%CE%A6%CE%B9%CE%BB%CE%B9%CF%80%CF%80%CE%B7%CF%83%CE%AF%CE%BF%CF%85%CF%82', 'Πρὸς Φιλιππησίους'),
            'Eus3': ('https://bibleox.com/grc/grc/w/%CE%95%CE%9A%CE%9A%CE%9B%CE%97%CE%A3%CE%99%CE%91%CE%A3%CE%A4%CE%99%CE%9A%CE%97%CE%A3_%CE%99%CE%A3%CE%A4%CE%9F%CE%A1%CE%99%CE%91%CE%A3-3', 'Ἐκκλησιαστικὴ Ἱστορία Γ΄'),
        },
    },
    'pol': {
        'blocks': 'blocks_pol.json', 'parts': 'pol_parts', 'out': 'pol_body.html',
        'works': {
            'PlkFl': ('https://bibleox.com/grc/grc/w/%CE%95%CF%80%CE%B9%CF%83%CF%84%CE%BF%CE%BB%CE%AE-%CE%A0%CE%BF%CE%BB%CF%85%CE%BA%CE%AC%CF%81%CF%80%CE%BF%CF%85-%CF%80%CF%81%CE%BF%CF%82-%CE%A6%CE%B9%CE%BB%CE%B9%CF%80%CF%80%CE%B7%CF%83%CE%AF%CE%BF%CF%85%CF%82', 'Πρὸς Φιλιππησίους'),
            'Mart': ('https://bibleox.com/grc/grc/w/%CE%9C%CE%B1%CF%81%CF%84%CF%8D%CF%81%CE%B9%CE%BF_%CF%84%CE%BF%CF%85_%CE%91%CE%B3%CE%AF%CE%BF%CF%85_%CE%A0%CE%BF%CE%BB%CF%85%CE%BA%CE%AC%CF%81%CF%80%CE%BF%CF%85_%CE%95%CF%80%CE%B9%CF%83%CE%BA%CF%8C%CF%80%CE%BF%CF%85_%CE%A3%CE%BC%CF%8D%CF%81%CE%BD%CE%B7%CF%82', 'Μαρτύριο τοῦ ἁγίου Πολυκάρπου'),
            'Eus3': ('https://bibleox.com/grc/grc/w/%CE%95%CE%9A%CE%9A%CE%9B%CE%97%CE%A3%CE%99%CE%91%CE%A3%CE%A4%CE%99%CE%9A%CE%97%CE%A3_%CE%99%CE%A3%CE%A4%CE%9F%CE%A1%CE%99%CE%91%CE%A3-3', 'Ἐκκλησιαστικὴ Ἱστορία Γ΄'),
        },
    },
}
TOK = {}
for _b in ('', 'b'):
    for _m in ('', 'm'):
        for _e in ('', 'e'):
            for _u in ('', 'u'):
                _n = _b + _m + _e + _u
                if not _n:
                    continue
                TOK[_n] = tuple(x for x, on in (('strong', _b), ('mark', _m), ('em', _e), ('u', _u)) if on)
TOK['strong'] = ('strong',)
TOK['mark'] = ('mark',)
TOK['em'] = ('em',)


def tag_counts(s, kind='gr'):
    c = {'strong': 0, 'mark': 0, 'em': 0, 'u': 0}
    for m in re.finditer(r'<(/?)(strong|mark|em|u)>', s):
        if m.group(1) == '/':
            continue
        t = m.group(2)
        if kind == 'ru':
            for k, tags in TOK.items():
                if k == t:
                    for x in tags:
                        c[x] += 1
                    break
        else:
            c[t] = c.get(t, 0) + 1
    return c


def ru_counts(block):
    c = {'strong': 0, 'mark': 0, 'em': 0, 'u': 0}
    for g in block['groups']:
        for p in g:
            for m in re.finditer(r'<(/?)([a-z]+)>', p):
                if m.group(1) == '/':
                    continue
                for x in TOK.get(m.group(2), ()):
                    c[x] = c.get(x, 0) + 1
    return c


def cut(works, w, ch, frm, to):
    paras = works.get(w, {}).get(str(ch))
    if not paras:
        return None, 'нет главы'
    text = ' '.join(paras)
    i = text.find(frm)
    if i < 0:
        return None, f'from не найдено: {frm[:30]}'
    j = text.find(to, i)
    if j < 0:
        return None, f'to не найдено: {to[:30]}'
    return text[i:j + len(to)], None


def escape_text_lt(s):
    return re.sub(r'<(?!/?(?:strong|mark|em|u)>)', '&lt;', s)


def apply_marks(t, marks):
    out = t
    for mk in marks:
        tag, ph = mk[0], mk[1]
        nth = mk[2] if len(mk) > 2 else 0
        idxs, at = [], out.find(ph)
        while at >= 0:
            idxs.append(at)
            at = out.find(ph, at + 1)
        if len(idxs) <= nth:
            return None, f'фраза не найдена: {ph[:30]}'
        s = idxs[nth]
        out = out[:s] + f'<{tag}>' + ph + f'</{tag}>' + out[s + len(ph):]
    return out, None


def main(page):
    cfg = META[page]
    parts = __import__(cfg['parts'])
    works = json.load(open(os.path.join(HERE, 'works.json'), encoding='utf-8'))
    blocks = json.load(open(os.path.join(HERE, cfg['blocks']), encoding='utf-8'))
    quotes = {}
    for fn in glob.glob(os.path.join(HERE, 'out', f'{page}*.json')):
        quotes.update(json.load(open(fn, encoding='utf-8')))
    chunks, problems = [], []
    last = None
    for b in blocks:
        t = b['type']
        if t in ('h2', 'h3', 'h4', 'table'):
            txt = parts.PARTS.get(b['id'])
            if txt is None:
                problems.append(f'нет перевода B{b["id"]} ({t})')
                continue
            chunks.append((b['id'], f'<{t}>{txt}</{t}>' if t != 'table' else txt))
        elif t == 'p':
            txt = parts.PARTS.get(b['id'])
            if txt is None:
                problems.append(f'нет перевода B{b["id"]} (p)')
                continue
            chunks.append((b['id'], f'<p>{txt}</p>'))
        elif t == 'quote':
            last = b
            if b['q'] in parts.OWN:
                paras = []
                for g in parts.OWN[b['q']]:
                    for p in g:
                        paras.append('<p>' + p + '</p>')
                chunks.append((b['id'], '<blockquote>' + ''.join(paras) + '</blockquote>'))
                continue
            val = quotes.get(str(b['id']))
            if val is None:
                problems.append(f'нет цитаты Q{b["q"]} (B{b["id"]})')
                continue
            made, errs, si = [], [], 0
            ru_paras = [p for g in b['groups'] for p in g]
            for ru_p in ru_paras:
                plain_ru = re.sub(r'\s+', ' ', _html.unescape(re.sub('<[^>]+>', '', ru_p))).strip()
                if plain_ru in ('...', '…', '<...>', '<…>'):
                    glyph = {'...': '...', '…': '…', '<...>': '&lt;...&gt;',
                             '<…>': '&lt;…&gt;'}[plain_ru]
                    nxt = val['paras'][si] if si < len(val['paras']) else None
                    if nxt and nxt.get('own'):
                        si += 1
                        made.append('<p>' + nxt.get('text', glyph) + '</p>')
                    else:
                        made.append('<p>' + glyph + '</p>')
                    continue
                if si >= len(val['paras']):
                    errs.append('не хватает спецификации')
                    made.append('<p></p>')
                    continue
                spec = val['paras'][si]
                si += 1

                if spec.get('own'):
                    made.append('<p>' + spec.get('text', '') + '</p>')
                    continue
                txt, err = cut(works, spec['w'], spec['ch'], spec['from'], spec['to'])
                if err:
                    errs.append(err)
                    made.append('<p></p>')
                    continue
                txt, err = apply_marks(txt, spec.get('marks', []))
                if err:
                    errs.append(err)
                    made.append('<p></p>')
                    continue
                made.append('<p>' + escape_text_lt(txt) + '</p>')
            # цитата, покрывающая несколько глав: остаток спецификаций — в последний абзац
            tail = []
            while si < len(val['paras']):
                spec = val['paras'][si]
                si += 1
                if spec.get('own'):
                    tail.append(spec.get('text', ''))
                    continue
                txt, err = cut(works, spec['w'], spec['ch'], spec['from'], spec['to'])
                if err:
                    errs.append(err)
                    continue
                txt, err = apply_marks(txt, spec.get('marks', []))
                if err:
                    errs.append(err)
                    continue
                tail.append(escape_text_lt(txt))
            if tail and made:
                lastp = made[-1]
                if lastp.endswith('</p>'):
                    made[-1] = lastp[:-4] + ' ' + ' '.join(tail) + '</p>'
            if errs:
                problems.append(f'Q{b["q"]}: ' + '; '.join(errs))
            flat, idx = [], 0
            for gi, g in enumerate(b['groups']):
                if gi:
                    flat.append(SEP)
                for _ in g:
                    flat.append(made[idx])
                    idx += 1
            chunks.append((b['id'], '<blockquote>' + ''.join(flat) + '</blockquote>'))
            rc, ec = ru_counts(b), {'strong': 0, 'mark': 0, 'em': 0, 'u': 0}
            for p in made:
                for m in re.finditer(r'<(/?)(strong|mark|em|u)>', p):
                    if m.group(1) != '/':
                        ec[m.group(2)] = ec.get(m.group(2), 0) + 1
            if rc != ec:
                problems.append(f'Q{b["q"]}: выделения ru={rc} gr={ec}')
        elif t == 'source':
            q = last
            if q is None or not q['source'] or q['q'] in parts.OWN:
                continue
            val = quotes.get(str(q['id']))
            if not val or not val.get('paras'):
                problems.append(f'Q{q["q"]}: нет данных для ссылки')
                continue
            spec = next((s for s in val['paras'] if not s.get('own')), None)
            title_ru = (q['source']['title'] + q['source']['tail']) if q['source'] else ''
            w = ch = None
            if spec is not None:
                w, ch = spec['w'], spec['ch']
            else:
                # цитата собрана из нескольких глав: труд берём из подписи ru
                KEY = [('Тралл', 'Tral'), ('Смирн', 'Smyr'), ('Поликарп', 'Pol'),
                       ('Магнез', 'Mag'), ('иладельф', 'Phil'), ('Филипп', 'PlkFl'),
                       ('Фл', 'Phil'), ('Еф', 'Ef'), ('Рим', 'Rom'),
                       ('Церковная история', 'Eus3')]
                for k, ww in KEY:
                    if k.lower() in title_ru.lower() and ww in cfg['works']:
                        w = ww
                        break
            if w is None:
                problems.append(f'Q{q["q"]}: нет источника')
                continue
            url, title = cfg['works'][w]
            href = url + (f'#HH-{ch}' if ch else '')
            chunks.append((b['id'], f'<p>(<a href="{href}">{title}</a>)</p>'))
    body = ''.join(x for _, x in chunks)
    open(os.path.join(HERE, cfg['out']), 'w', encoding='utf-8').write(body)
    print(page, 'блоков:', len(blocks), 'цитат:', len([b for b in blocks if b['type'] == 'quote']))
    print('кириллица:', len(re.findall(r'[А-Яа-яЁё]', body)), 'размер:', len(body))
    print('проблем:', len(problems))
    for p in problems[:30]:
        print('  !!', p)
    for tag in ('p', 'blockquote', 'strong', 'mark', 'em', 'u', 'a', 'h2', 'h3', 'table'):
        o = len(re.findall(rf'<{tag}[ >]', body))
        c = body.count(f'</{tag}>')
        if o != c:
            print(f'  тег {tag}: открыт {o}, закрыт {c}')


if __name__ == '__main__':
    main(sys.argv[1])
