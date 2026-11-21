#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Сборка греческого body страницы Иустина из ru-блоков и греческих цитат."""
import json, os, re, glob, sys, html as _html

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import my_parts  # noqa: E402
import review_quotes  # noqa: E402

SEP = '<p>&lt;…&gt;</p>'
URLS = {
    'A1': 'https://bibleox.com/grc/grc/w/%CE%99%CE%BF%CF%85%CF%83%CF%84%CE%AF%CE%BD%CE%BF%CF%82_%CE%A6%CE%B9%CE%BB%CF%8C%CF%83%CE%BF%CF%86%CE%BF%CF%82_%E1%BC%88%CF%80%CE%BF%CE%BB%CE%BF%CE%B3%CE%AF%CE%B1_1',
    'A2': 'https://bibleox.com/grc/grc/w/%CE%99%CE%BF%CF%85%CF%83%CF%84%CE%AF%CE%BD%CE%BF%CF%82_%CE%A6%CE%B9%CE%BB%CF%8C%CF%83%CE%BF%CF%86%CE%BF%CF%82_%E1%BC%88%CF%80%CE%BF%CE%BB%CE%BF%CE%B3%CE%AF%CE%B1_2',
    'Dial': 'https://bibleox.com/grc/grc/w/%CE%99%CE%BF%CF%85%CF%83%CF%84%CE%AF%CE%BD%CE%BF%CF%82_%CE%BF_%CE%A6%CE%B9%CE%BB%CF%8C%CF%83%CE%BF%CF%86%CE%BF%CF%82-%CE%94%CE%B9%CE%AC%CE%BB%CE%BF%CE%B3%CE%BF_%CF%80%CF%81%CE%BF%CF%82_%CE%A4%CF%81%CF%8D%CF%86%CF%89%CE%BD%CE%B1',
}
TITLES = {'A1': 'Ἀπολογία 1', 'A2': 'Ἀπολογία 2', 'Dial': 'Διάλογος πρὸς Τρύφωνα'}
TITLE_MAP = {
    'Апология 1, гл. 61': 'Ἀπολογία 1, κεφ. 61',
    'Разговор с Трифоном иудеем, 28': 'Διάλογος πρὸς Τρύφωνα, 27',
    'Апология I, 65-67': 'Ἀπολογία 1, 65-67',
}
TOK = {'strong': ('strong',), 'b': ('strong',), 'mark': ('mark',), 'm': ('mark',),
       'bm': ('strong', 'mark'), 'e': ('em',),
       'eb': ('em', 'strong'), 'em': ('em', 'mark'), 'ebm': ('em', 'strong', 'mark')}
# для готового греческого текста <em> — просто курсив (в ru-разметке «em» = курсив+маркер)
TOK_GR = dict(TOK, em=('em',))


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


def anchor(w, ch):
    if str(ch) == '1':
        return '#HH-1-' if w != 'A2' else '#HH-1'
    return '#HH-' + str(ch)


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


FIXUPS = [
    # явная опечатка электронной версии (Диалог 44): σβεςθήσεται → σβεσθήσεται
    ('σβεςθήσεται', 'σβεσθήσεται'),
]


def escape_text_lt(s):
    # тексто-критические <...> издания: экранируем только «чужие» угловые скобки
    return re.sub(r'<(?!/?(?:strong|mark|em)>)', '&lt;', s)


PUNCT = set(' .,·;:!·—–\'"»«()')


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


def load_quotes():
    data = {}
    for fn in sorted(glob.glob(os.path.join(HERE, 'out', '*.json'))):
        d = json.load(open(fn, encoding='utf-8'))
        for k, v in d.items():
            if k in data:
                raise SystemExit(f'дубль блока {k}: {fn}')
            data[k] = v
    for q, v in review_quotes.build().items():
        data[('rev', q)] = v
    return data


def main():
    blocks = json.load(open(os.path.join(HERE, 'blocks.json'), encoding='utf-8'))
    works = json.load(open(os.path.join(HERE, 'works.json'), encoding='utf-8'))
    quotes = load_quotes()
    parts = my_parts.PARTS
    chunks, problems, report = [], [], []
    last_quote = None
    for b in blocks:
        if b['id'] in getattr(my_parts, 'SKIP', ()):
            continue
        t = b['type']
        if t in ('h2', 'h3'):
            txt = parts.get(b['id'])
            if txt is None:
                problems.append(f'нет перевода заголовка B{b["id"]}')
                continue
            chunks.append((b['id'], f'<{t}>{txt}</{t}>'))
        elif t == 'p':
            txt = parts.get(b['id'])
            if txt is None:
                problems.append(f'нет перевода абзаца B{b["id"]}')
                continue
            chunks.append((b['id'], f'<p>{txt}</p>'))
        elif t == 'quote':
            last_quote = b
            rev = quotes.get(('rev', b['q']))
            val = quotes.get(str(b['id']))
            if rev is None and val is None:
                problems.append(f'нет цитаты Q{b["q"]} (B{b["id"]})')
                continue
            if rev is not None:
                paras = rev['quote']
                chunks.append((b['id'], '<blockquote>' + ''.join(paras) + '</blockquote>'))
                report.append((b['q'], b['id'], rev['title']))
            else:
                specs = val['paras']
                ru_paras = [p for g in b['groups'] for p in g]
                real = [p for p in ru_paras
                        if re.sub(r'\s+', ' ', _html.unescape(re.sub('<[^>]+>', '', p))).strip()
                        not in ('...', '…', '<...>', '<…>')]
                real_specs = [s for s in specs
                              if not (s.get('own') and ('&lt;' in (s.get('text') or '')
                                                        or (s.get('text') or '').strip() in ('...', '…')))]
                if len(real_specs) != len(real):
                    problems.append(f'Q{b["q"]}: спецификаций {len(real_specs)}, '
                                    f'реальных ru-абзацев {len(real)}')
                made, errs = [], []
                si = 0
                for ru_p in ru_paras:
                    plain_ru = re.sub(r'\s+', ' ', _html.unescape(re.sub('<[^>]+>', '', ru_p))).strip()
                    is_placeholder = plain_ru in ('...', '…', '<...>', '<…>')
                    if is_placeholder:
                        # если агент всё же дал own-спеку на заглушку — используем её
                        nxt = specs[si] if si < len(specs) else None
                        if nxt and nxt.get('own'):
                            si += 1
                            made.append('<p>' + nxt.get('text', '&lt;…&gt;') + '</p>')
                        else:
                            glyph = {'...': '...', '…': '…',
                                     '<...>': '&lt;...&gt;', '<…>': '&lt;…&gt;'}[plain_ru]
                            made.append('<p>' + glyph + '</p>')
                        continue
                    if si >= len(specs):
                        errs.append(f'не хватает спецификации для абзаца {len(made)}')
                        made.append('<p></p>')
                        continue
                    spec = specs[si]
                    si += 1
                    if spec.get('own'):
                        made.append('<p>' + spec.get('text', '') + '</p>')
                        continue
                    text, err = cut(works, spec['w'], spec['ch'], spec['from'], spec['to'])
                    if err:
                        errs.append(err)
                        made.append('<p></p>')
                        continue
                    text, err = apply_marks(text, spec.get('marks', []))
                    if err:
                        errs.append(err)
                        made.append('<p></p>')
                        continue
                    made.append('<p>' + escape_text_lt(text) + '</p>')
                if errs:
                    problems.append(f'Q{b["q"]}: ' + '; '.join(errs))
                # собрать с разделителями по ru-структуре
                flat, idx = [], 0
                for gi, g in enumerate(b['groups']):
                    if gi:
                        flat.append(SEP)
                    for _ in g:
                        flat.append(made[idx])
                        idx += 1
                chunks.append((b['id'], '<blockquote>' + ''.join(flat) + '</blockquote>'))
                rc, ec = ru_counts(b), {'strong': 0, 'mark': 0, 'em': 0}
                for p in made:
                    cc = tag_counts(p)
                    for k in ec:
                        ec[k] += cc[k]
                if rc != ec:
                    problems.append(f'Q{b["q"]}: выделения ru={rc} gr={ec}')
                report.append((b['q'], b['id'], val.get('where', '')))
        elif t == 'source':
            q = last_quote
            if q is None or not q['source']:
                continue
            rev = quotes.get(('rev', q['q']))
            if rev is not None:
                chunks.append((b['id'], f'<p>(<a href="{rev["url"]}">{rev["title"]}</a>)</p>'))
                continue
            val = quotes.get(str(q['id'])) or {}
            specs = val.get('paras') or []
            w = specs[0]['w'] if specs and not specs[0].get('own') else None
            ch = specs[0]['ch'] if specs and not specs[0].get('own') else None
            if w is None:
                problems.append(f'Q{q["q"]}: не определить труд для ссылки')
                continue
            title = TITLE_MAP.get(q['source']['title'], TITLES.get(w, ''))
            url = URLS[w] + (anchor(w, ch) if not TITLE_MAP.get(q['source']['title']) else '')
            chunks.append((b['id'], f'<p>(<a href="{url}">{title}</a>)</p>'))
    out = []
    for bid, html in chunks:
        out.append(html)
        h4 = my_parts.H4_AFTER.get(bid)
        if h4:
            out.append(f'<h4>{h4}</h4>')
    body = ''.join(out)
    for a, bfix in FIXUPS:
        if body.count(a) == 0:
            print('  !! не найдена опечатка:', a)
        body = body.replace(a, bfix)
    open(os.path.join(HERE, 'gr_body.html'), 'w', encoding='utf-8').write(body)
    print('блоков:', len(blocks), 'цитат:', len([b for b in blocks if b['type'] == 'quote']))
    print('кириллица:', len(re.findall(r'[А-Яа-яЁё]', body)))
    print('размер:', len(body))
    print('проблем:', len(problems))
    for p in problems[:40]:
        print('  !!', p)
    for tag in ('p', 'blockquote', 'strong', 'mark', 'em', 'a', 'h2', 'h3', 'h4'):
        o = len(re.findall(rf'<{tag}[ >]', body))
        c = body.count(f'</{tag}>')
        if o != c:
            print(f'  тег {tag}: открыт {o}, закрыт {c}')
    print('ссылок:', len(re.findall(r'href="', body)))


if __name__ == '__main__':
    main()
