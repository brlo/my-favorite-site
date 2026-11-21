#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Сборка EN-body страницы Иустина из блоков ru, переводов координатора и цитат агентов."""
import json, os, re, glob, html, sys, urllib.parse

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import my_parts  # noqa: E402
import review_quotes  # noqa: E402

SEP = '<p>&lt;…&gt;</p>'
WORKS = {'A1': 'en_ap1.html', 'A2': 'en_ap2.html', 'Dial': 'en_dial.html'}

EN_BASE = 'https://bibleox.com/en/en/w/'
TITLE_MAP = {
    'Апология 1, гл. 61': 'Apology 1, ch. 61',
    'Разговор с Трифоном иудеем, 28': 'Dialogue with Trypho, 28',
}
SRC_MAP = [
    ('Апология_1', 'A1', EN_BASE + 'Justin_Philosopher-Apology_1', 'Apology 1'),
    ('Апология_2', 'A2', EN_BASE + 'Justin_Philosopher-Apology_2', 'Apology 2'),
    ('разговор_с_Трифоном', 'Dial', EN_BASE + 'Justin_Martyr-Dialogue_with_Trypho',
     'Dialogue with Trypho'),
    ('Iustin_Filosof/apologia', 'A1', EN_BASE + 'Justin_Philosopher-Apology_1#HH-65',
     'Apology 1, 65-67'),
    ('protiv-valentinian', 'T', EN_BASE + 'tertullian-against-the-valentinians#HH-'
     'Many-Eminent-Christian-Writers-Have-Carefully-and-Fully-Refuted-the-Heresy-These-'
     'the-Author-Makes-His-Own-Guides', 'Against the Valentinians, V'),
    ('Mefodij_Olimpijskij', 'M', EN_BASE + 'methodius-from-the-discourse-on-the-resurrection',
     'On the Resurrection, against Origen'),
    ('Epifanij_Kiprskij', 'E',
     'https://azbyka.ru/otechnik/Epifanij_Kiprskij/na-vosemdesjaty-eresej-panarij-ili-kovcheg',
     'Against Heresies'),
    ('o-prisnodevstve', 'J1', EN_BASE + 'jerome-the-perpetual-virginity-of-blessed-mary',
     'On the Perpetual Virginity of the Blessed Mary'),
    ('o_znamenityh', 'J2', EN_BASE + '7fQb_De_Viris_Illustribus_On_Illustrious_Men'
     '#HH-23-Justin-Martyr', 'On Illustrious Men'),
    ('Feodorit_Kirskij', 'F', 'https://azbyka.ru/otechnik/Feodorit_Kirskij/pisma/1', 'Letters'),
]


def plain(s):
    s = re.sub(r'<[^>]+>', '', s)
    s = html.unescape(s)
    return re.sub(r'\s+', ' ', s).strip()


def plain_norm(s):
    return re.sub(r'\s+', '', plain(s))


_work = {}


def work_chapters(w):
    if w not in _work:
        h = open(os.path.join(HERE, WORKS[w]), encoding='utf-8').read()
        parts = re.split(r'<h2[^>]*>(.*?)</h2>', h)
        _work[w] = [(parts[i].strip(), plain_norm(parts[i + 1]))
                    for i in range(1, len(parts), 2)]
    return _work[w]


def chapter_has(w, n, text):
    for name, body in work_chapters(w):
        if name == str(n):
            return plain_norm(text) in body
    return False


def first_chapter(w, text):
    t = plain_norm(text)
    for name, body in work_chapters(w):
        if t in body:
            return name
    return None


def load_quotes():
    data = {}
    for fn in sorted(glob.glob(os.path.join(HERE, 'out', '*.json'))):
        d = json.load(open(fn, encoding='utf-8'))
        for k, v in d.items():
            if k in data:
                raise SystemExit(f'дубль блока {k} в {fn}')
            data[k] = v
    rev = review_quotes.build()
    for q, v in rev.items():
        # id блока: находим по q
        data[('q', q)] = v
    return data



# Явные опечатки электронного текста ANF (исправляются с оговоркой в references)
FIXUPS = [
    ('suflcr persecution', 'suffer persecution'),
    ('for He will not hear yon', 'for He will not hear you'),
    ('and shah save', 'and shall save'),
    ('in the nay fie ate of the tree', 'in the day he ate of the tree'),
    ('of Genist , Meristae,Gelilaeans', 'of Genistae, Meristae, Gelilaeans'),
    ('in which He would come glorious. and Judge of all',
     'in which He would come glorious, and Judge of all'),
    ('all the souls of similiar righteous men', 'all the souls of similar righteous men'),
    ('are let in existence', 'are yet in existence'),
    ('sent Him away as the scope [goat]', 'sent Him away as the scape [goat]'),
    ('for he is distaste fill to us', 'for he is distasteful to us'),
    ('who fails away from piety', 'who falls away from piety'),
    ('His power and role', 'His power and rule'),
    ('the bloOd of salvation', 'the blood of salvation'),
    ('Him self', 'Himself'),
    ('</mark></strong>, land will not condemn', '</mark></strong>, and will not condemn'),
]

def main():
    blocks = json.load(open(os.path.join(HERE, 'blocks.json'), encoding='utf-8'))
    quotes = load_quotes()
    by_q = {b['q']: b for b in blocks if b['type'] == 'quote'}
    parts = my_parts.PARTS
    chunks = []
    report = []
    problems = []
    last_quote = None
    for b in blocks:
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
            val = quotes.get(str(b['id'])) or quotes.get(('q', b['q']))
            if val is None:
                problems.append(f'нет цитаты Q{b["q"]} (B{b["id"]})')
                continue
            paras = val['quote']
            # структурная сверка
            groups, cur = [], []
            for p in paras:
                if p == SEP:
                    groups.append(cur)
                    cur = []
                else:
                    cur.append(p)
            groups.append(cur)
            ru_shape = [len(g) for g in b['groups']]
            en_shape = [len(g) for g in groups]
            if ru_shape != en_shape:
                problems.append(f'Q{b["q"]}: структура ru {ru_shape} != en {en_shape}')
            # ру-абзац «...» (не разделитель <…>) остаётся многоточием и в en
            flat_ru = [x for g in b['groups'] for x in g]
            ci = 0
            for gi, g in enumerate(groups):
                for pi, para in enumerate(g):
                    if ci < len(flat_ru) and plain(flat_ru[ci]) in ('...', '…'):
                        groups[gi][pi] = '<p>...</p>'
                    ci += 1
            flat = []
            for gi, g in enumerate(groups):
                if gi:
                    flat.append(SEP)
                flat.extend(g)
            chunks.append((b['id'], '<blockquote>' + ''.join(flat) + '</blockquote>'))
            report.append((b['q'], b['id'], val.get('where', '')))
        elif t == 'source':
            q = last_quote
            if q is None or not q['source']:
                continue
            href = urllib.parse.unquote(q['source']['href'])
            base = None
            for key, w, url, title in SRC_MAP:
                if key in href:
                    base = (w, url, title)
                    break
            if base is None:
                problems.append(f'Q{q["q"]}: неизвестный источник {href[:80]}')
                continue
            w, url, title = base
            title = TITLE_MAP.get(q['source']['title'], title)
            val = quotes.get(str(q['id'])) or quotes.get(('q', q['q'])) or {}
            # якорь главы для трудов Иустина
            where = val.get('where', '')
            if w in WORKS and '#' not in url:
                en_paras = [plain(x) for x in val.get('quote', []) if x != SEP]
                nums = re.findall(r'(?:A1|A2|Dial)\s+(\d+)', where)
                n = None
                def in_chap(cand, t):
                    variants = [t, t.replace('byfire', 'bytire'),
                                t[:120], t[:80], t[:60]]
                    return any(chapter_has(w, cand, v) for v in variants if v)

                for cand in nums:
                    if any(in_chap(cand, t) for t in en_paras):
                        n = cand
                        break
                if n is None:
                    for t in en_paras:
                        n = first_chapter(w, t)
                        if n:
                            break
                if n:
                    url += '#HH-' + n
            tail = q['source']['tail']
            tail = re.sub(r'^\s*,\s*', ', ', tail).strip()
            chunks.append((b['id'], f'<p>(<a href="{url}">{title}</a>{tail})</p>'))
    out = []
    for bid, html in chunks:
        out.append(html)
        h4 = my_parts.H4_AFTER.get(bid)
        if h4:
            out.append(f'<h4>{h4}</h4>')
    body = ''.join(out)
    body = re.sub(r'(?<=[a-zA-Z,\]])\[', ' [', body)
    body = re.sub(r'(?<=[a-z])\(', ' (', body)
    for a, bfix in FIXUPS:
        cnt = body.count(a)
        if cnt == 0:
            print('  !! не найдена опечатка:', a[:50])
        body = body.replace(a, bfix)
    open(os.path.join(HERE, 'en_body.html'), 'w', encoding='utf-8').write(body)

    print('блоков:', len(blocks), 'цитат:', len([b for b in blocks if b['type'] == 'quote']))
    cyr = re.findall(r'[А-Яа-яЁё]', body)
    print('кириллица в теле:', len(cyr), cyr[:10])
    print('размер body:', len(body))
    print('проблем:', len(problems))
    for p in problems:
        print('  !!', p)
    # грубая проверка парности
    for tag in ('p', 'blockquote', 'strong', 'mark', 'em', 'a', 'h2', 'h3'):
        o = len(re.findall(rf'<{tag}[ >]', body))
        c = body.count(f'</{tag}>')
        if o != c:
            print(f'  тег {tag}: открыт {o}, закрыт {c}')
    # якоря ссылок
    links = re.findall(r'href="([^"]+)"', body)
    print('ссылок:', len(links), 'уникальных:', len(set(links)))
    from collections import Counter
    for u, n in Counter(links).most_common():
        if n > 1:
            print('   повтор', n, u[:100])


if __name__ == '__main__':
    main()
