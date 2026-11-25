#!/usr/bin/env python3
"""Сборка пакетов для агентов-переводчиков (en/grc) страницы Иринея."""
import json
import os
import re
import unicodedata

from lxml import html as LH

HERE = os.path.dirname(os.path.abspath(__file__))
TMP = os.environ.get('IREN_TMP') or HERE
DB = os.path.join(TMP, 'db')

# ---------------------------------------------------------------- RU blocks
blocks = json.load(open(os.path.join(TMP, 'blocks.json')))

# ---------------------------------------------------------------- работы
# lang -> work -> (page_id, heading_tag)
WORKS = {
    'en': {
        'b1': (543, 'h2'), 'b2': (544, 'h2'), 'b3': (545, 'h2'),
        'b4': (546, 'h2'), 'b5': (547, 'h2'),
        'dem': (542, None), 'frag': (950, 'h2'),
        'justin_dial': (406, 'h2'), 'justin_apol1': (416, 'h2'),
        'polycarp': (404, 'h2'),
    },
    'la': {
        'b1': (1511, 'h2'), 'b2': (2563, 'h2'), 'b3': (2564, 'h2'),
        'b4': (2565, 'h2'), 'b5': (2566, 'h2'),
    },
    'grc': {
        'b1': (946, 'h2'), 'b2': (945, 'h2'), 'b3': (947, 'h2'),
        'b4': (948, 'h2'), 'b5': (949, 'h2'),
        'frag': (607, 'h2'),
        'justin_dial': (411, 'h2'), 'justin_apol1': (415, 'h2'),
        'polycarp': (410, 'h2'),
    },
    'ru': {
        'dem': (459, 'h3'),
    },
}

PATHS = {
    'la': {
        'b1': 'LATIN-Adversus_haereses_LIBER_I',
        'b2': 'LATIN-Adversus_haereses_LIBER_II',
        'b3': 'LATIN-Adversus_haereses,_LIBER_III',
        'b4': 'LATIN-Adversus_haereses,_LIBER_IV',
        'b5': 'LATIN-Adversus_haereses,_LIBER_V',
    },
    'en': {
        'b1': 'irenaeus-against-heresies-b1', 'b2': 'irenaeus-against-heresies-b2',
        'b3': 'irenaeus-against-heresies-b3', 'b4': 'irenaeus-against-heresies-b4',
        'b5': 'irenaeus-against-heresies-b5',
        'dem': 'YQKGC4v5_The_Proof_Demonstration_of_the_Apostolic_Preaching',
        'frag': '8yk4_Fragments',
        'justin_dial': 'Justin_Martyr-Dialogue_with_Trypho',
        'justin_apol1': 'Justin_Philosopher-Apology_1',
        'polycarp': 'Martyrdom-of-Polycarp',
    },
    'grc': {
        'b1': 'Az9E_Ἔλεγχος_καὶ_ἀνατροπὴ_τῆς_ψευδωνύμου_γνώσεως_Κατὰ_αἱρέσεων__Βιβλίον_1',
        'b2': 'b9vD_Ἔλεγχος_καὶ_ἀνατροπὴ_τῆς_ψευδωνύμου_γνώσεως_Κατὰ_αἱρέσεων__Βιβλίον_2',
        'b3': 'jzHD_Ἔλεγχος_καὶ_ἀνατροπὴ_τῆς_ψευδωνύμου_γνώσεως_Κατὰ_αἱρέσεων__Βιβλίον_3',
        'b4': 'NRko_Ἔλεγχος_καὶ_ἀνατροπὴ_τῆς_ψευδωνύμου_γνώσεως_Κατὰ_αἱρέσεων__Βιβλίον_4',
        'b5': '8q46_Ἔλεγχος_καὶ_ἀνατροπὴ_τῆς_ψευδωνύμου_γνώσεως_Κατὰ_αἱρέσεων__Βιβλίον_5',
        'frag': 'xg4M_Θραύσματα_Θραύσματα',
        'justin_dial': 'Ιουστίνος_ο_Φιλόσοφος-Διάλογο_προς_Τρύφωνα',
        'justin_apol1': 'Ιουστίνος_Φιλόσοφος_Ἀπολογία_1',
        'polycarp': 'Μαρτύριο_του_Αγίου_Πολυκάρπου_Επισκόπου_Σμύρνης',
    },
}


def anchor_of(title, counters):
    t = re.sub(r'[^0-9A-Za-z\u00c0-\u024f\u0370-\u03ff\u1f00-\u1fff\s\-]', '', title)
    t = t.replace(' ', '-')
    idx = counters[t] = counters.get(t, 0) + 1
    return 'HH' + (str(idx) if idx > 1 else '') + '-' + t


_cache = {}


def load_work(lang, key):
    ck = (lang, key)
    if ck in _cache:
        return _cache[ck]
    page_id, htag = WORKS[lang][key]
    body = open(os.path.join(DB, f'{page_id}.html'), encoding='utf-8').read()
    doc = LH.fromstring('<div>' + body + '</div>')
    root = doc.xpath('//div')[0]
    chapters = []
    counters = {}
    cur = {'title': '', 'anchor': None, 'paras': []}
    chapters.append(cur)
    for el in root:
        if htag and el.tag == htag:
            raw = el.text_content()
            cur = {'title': raw.strip(), 'anchor': anchor_of(raw, counters), 'paras': []}
            chapters.append(cur)
        elif el.tag in ('p', 'blockquote'):
            cur['paras'].append({'html': LH.tostring(el, encoding='unicode'),
                                 'text': el.text_content()})
        elif el.tag in ('ul', 'ol', 'table'):
            for li in el.xpath('.//li'):
                cur['paras'].append({'html': LH.tostring(li, encoding='unicode'),
                                     'text': li.text_content()})
    if not chapters[0]['paras']:
        chapters.pop(0)
    _cache[ck] = chapters
    return chapters


def chapter_titles(lang, key):
    return [(c['title'], c['anchor']) for c in load_work(lang, key)]


def norm(s):
    s = s.replace('ё', 'е').replace('Ё', 'Е').lower()
    s = unicodedata.normalize('NFKC', s)
    return ' '.join(re.sub(r'[^0-9a-z\u0430-\u044f]+', ' ', s).split())


# --------------------------------------------------------------- карта цитат
LOCS = {x['block']: x['loc'] for x in json.load(open(os.path.join(TMP, 'quote_locs.json')))}

# ручные уточнения: block -> {work, chapters, para_hint}
# work: b1..b5 (Против ересей), dem, frag, justin_dial, justin_apol1, polycarp
OVERRIDES = {
    11: {'work': 'polycarp', 'chapters': []},          # колофон «Мученичества Поликарпа»
    79: {'work': 'frag', 'chapters': [33]},
    106: {'work': 'justin_dial', 'chapters': [138]},
    108: {'work': 'justin_apol1', 'chapters': [61]},
    120: {'work': 'dem', 'chapters': list(range(87, 97))},
    130: {'work': 'dem', 'chapters': [96]},
    159: {'work': 'b1', 'chapters': [23]},             # латинский текст
    145: {'work': 'b3', 'chapters': [2, 3, 4]},
    183: {'work': 'b4', 'chapters': [18, 19]},
}
# у цитаты 84/87 источник — кн. IV, гл. 18; у 82 — кн. V, гл. 2 (в RU подписано «Книга 5»)
MAP = {}
for bid, loc in LOCS.items():
    if bid in OVERRIDES:
        MAP[bid] = dict(OVERRIDES[bid])
        continue
    if not loc:
        continue
    work = 'b' + loc['work'] if loc['work'] in ('1', '2', '3', '4', '5') else loc['work']
    MAP[bid] = {'work': work, 'chapters': [loc['chapter']],
                'para_hint': loc['para'], 'coverage': loc['coverage']}

json.dump(MAP, open(os.path.join(TMP, 'map.json'), 'w'), ensure_ascii=False, indent=1)

CHUNKS = [
    ('C0', 0, 46),
    ('C1', 47, 64),
    ('C2', 65, 88),
    ('C3', 89, 116),
    ('C4', 117, 131),
    ('C5', 132, 151),
    ('C6', 152, 178),
    ('C7', 179, 184),
]

SKIP_GRC = {158, 159, 160}   # латинский довесок к цитате о Симоне волхве
COORD = {1, 2, 4, 5, 77, 180, 181}   # блоки, которые делает координатор


def src_line_text(b):
    return re.sub(r'<[^>]+>', '', b.get('html', '')).strip()


def is_src_line(b):
    if b['k'] != 'p':
        return False
    t = src_line_text(b)
    return t.startswith('(') and ('<a ' in b['html'] or t.startswith('(источник'))


def trim_html(h):
    return h


def quote_block(block, lang):
    """Секция пакета для одной цитаты."""
    bid = block['id']
    spec = MAP[bid]
    work = spec['work']
    out = []
    out.append(f"### Блок {bid}: ЦИТАТА (RU, дословно переведена с издания)")
    out.append('```')
    out.append(re.sub(r'\s+', ' ', block['text']).strip())
    out.append('```')
    out.append('Выделения в RU (число и вид должны сохраниться):')
    for m in block['marks']:
        out.append(f"- {m[0]}: «{m[1]}»" + (f" (вхождение {m[2]})" if len(m) > 2 else ''))
    out.append('')
    out.append(f"Работа: `{work}`, главы: {spec['chapters'] or '— (колофон, последняя глава)'}")
    # целевые тексты
    if lang == 'en':
        out.append(en_material(work, spec['chapters']))
    else:
        out.append(grc_material(work, spec['chapters']))
    return '\n'.join(out)


def chapter_text(lang, work, num, max_len=14000):
    chs = load_work(lang, work)
    for c in chs:
        m = re.match(r'^\s*(\d+)', c['title'])
        n = int(m.group(1)) if m else None
        if n == num:
            txt = '\n\n'.join(p['text'] for p in c['paras'] if p['text'].strip())
            if len(txt) > max_len:
                txt = txt[:max_len] + '\n[…текст главы обрезан…]'
            return c, txt
    return None, None


def en_material(work, chapters):
    out = []
    if work == 'dem':
        chs = load_work('en', 'dem')
        paras = chs[0]['paras']
        out.append('«Demonstration» (ANF): нужные разделы (полный текст — '
                   '`tmp/iren/corpus/en_dem.txt`):')
        for p in paras:
            m = re.match(r'^\s*(\d+)\.', p['text'])
            if m and int(m.group(1)) in chapters:
                out.append(p['text'])
        return '\n'.join(out)
    for num in chapters:
        c, txt = chapter_text('en', work, num)
        if c is None:
            out.append(f'[!] глава {num} не найдена в en/{work}')
            continue
        out.append(f"--- en/{work}, глава {num} (anchor `{c['anchor']}`) ---")
        out.append(txt)
    if work == 'polycarp':
        chs = load_work('en', 'polycarp')
        c = chs[-1]
        out.append(f"--- en/polycarp, глава «{c['title']}» (anchor `{c['anchor']}`) ---")
        out.append('\n\n'.join(p['text'] for p in c['paras']))
    if work in ('justin_dial', 'justin_apol1'):
        out.append(f"(главы {chapters} — по нумерации страницы en/{work})")
    return '\n'.join(out)


def grc_material(work, chapters):
    out = []
    if work == 'dem':
        out.append('«Доказательство апостольской проповеди» сохранилось только по-армянски; '
                   'греческого и латинского текста нет. Переводи с РУССКОГО (ниже) — '
                   'на политоническом греческом. Ссылку на библиотеку НЕ давать '
                   '(в references — помета).')
        chs = load_work('ru', 'dem')
        for c in chs:
            m = re.match(r'^\s*(\d+)', c['title'])
            if m and int(m.group(1)) in chapters:
                out.append(f"--- ru/dem, раздел {m.group(1)} ---")
                out.append('\n\n'.join(p['text'] for p in c['paras'] if p['text'].strip()))
        return '\n'.join(out)
    if work == 'polycarp':
        chs = load_work('grc', 'polycarp')
        c = chs[-1]
        out.append(f"--- grc/polycarp, глава «{c['title']}» (anchor `{c['anchor']}`) ---")
        out.append('\n\n'.join(p['text'] for p in c['paras']))
        return '\n'.join(out)
    for num in chapters:
        c, txt = chapter_text('grc', work, num)
        if c is None:
            out.append(f'[!] глава {num} не найдена в grc/{work} — см. латинский текст')
        else:
            out.append(f"--- grc/{work}, глава {num} (заголовок «{c['title']}», anchor `{c['anchor']}`) ---")
            out.append(txt)
    # латинский текст для сверки/перевода
    la_key = work if work.startswith('b') else None
    if la_key and la_key in WORKS['la']:
        for num in chapters:
            c, txt = chapter_text('la', la_key, num)
            if c:
                out.append(f"--- la/{la_key}, глава {num} (латинский текст; anchor `{c['anchor']}`) ---")
                out.append(txt)
    return '\n'.join(out)


def main():
    packs = os.path.join(TMP, 'packs')
    os.makedirs(packs, exist_ok=True)
    chunk_def = {}
    for name, start, end in CHUNKS:
        ids = list(range(start, end + 1))
        chunk_def[name] = ids
        lines = []
        for bid in ids:
            b = blocks[bid]
            if b['k'] in ('h2', 'h3'):
                lines.append(f"### Блок {bid}: ЗАГОЛОВОК {b['k']}\n```\n{b['t']}\n```\n")
            elif b['k'] == 'quote':
                lines.append(quote_block(b, 'en'))  # placeholder, заменим ниже
            elif is_src_line(b):
                lines.append(f"### Блок {bid}: СТРОКА-ИСТОЧНИК (генерируется автоматически, "
                             f"в ответ НЕ включать):\n```\n{src_line_text(b)}\n```\n")
            elif b['k'] == 'hr':
                lines.append(f"### Блок {bid}: <hr> (оставить как есть)\n")
            else:
                lines.append(f"### Блок {bid}: {b['k'].upper()}\n```html\n{b['html']}\n```\n")
        # сохраняем только «скелет» — материал подставляется при сборке конкретного языка
        chunk_def[name] = {'start': start, 'end': end}
    json.dump(chunk_def, open(os.path.join(TMP, 'chunks.json'), 'w'), ensure_ascii=False, indent=1)

    for lang in ('en', 'grc'):
        os.makedirs(os.path.join(packs, lang), exist_ok=True)
        for name, start, end in CHUNKS:
            lines = [f'# Пакет {name} ({lang}) — страница Иринея Лионского\n']
            for bid in range(start, end + 1):
                b = blocks[bid]
                if lang == 'grc' and bid in SKIP_GRC:
                    lines.append(f'### Блок {bid}: ПРОПУСТИТЬ (latin appendix; на grc-странице не нужен)\n')
                    continue
                if bid in COORD:
                    lines.append(f'### Блок {bid}: ОБРАБОТАЕТ КООРДИНАТОР — не переводить, в ответ НЕ включать\n')
                    continue
                if b['k'] in ('h2', 'h3'):
                    lines.append(f"### Блок {bid}: ЗАГОЛОВОК {b['k']}\n```\n{b['t']}\n```\n")
                elif b['k'] == 'quote':
                    lines.append(quote_block(b, lang))
                elif is_src_line(b):
                    lines.append(f"### Блок {bid}: СТРОКА-ИСТОЧНИК (в ответ НЕ включать, "
                                 f"соберётся автоматически):\n```\n{src_line_text(b)}\n```\n")
                elif b['k'] == 'hr':
                    lines.append(f"### Блок {bid}: <hr> (оставить как есть)\n")
                else:
                    lines.append(f"### Блок {bid}: {b['k'].upper()}\n```html\n{b['html']}\n```\n")
            open(os.path.join(packs, lang, f'{name}.md'), 'w', encoding='utf-8').write('\n'.join(lines))
    # корпуса для поиска
    corp = os.path.join(TMP, 'corpus')
    os.makedirs(corp, exist_ok=True)
    for lang in ('en', 'grc', 'la'):
        for key in WORKS[lang]:
            chs = load_work(lang, key)
            out = []
            for c in chs:
                out.append(f"=== {key} | {c['title']} | {c['anchor']} ===")
                out.extend(p['text'] for p in c['paras'])
            open(os.path.join(corp, f'{lang}_{key}.txt'), 'w', encoding='utf-8').write('\n'.join(out))
    print('готово')


if __name__ == '__main__':
    main()
