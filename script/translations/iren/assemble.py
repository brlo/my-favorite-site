#!/usr/bin/env python3
"""Сборка тела страницы Иринея из JSON-ответов агентов + проверки."""
import html as H
import json
import os
import re
import sys
import unicodedata
from urllib.parse import quote

HERE = os.path.dirname(os.path.abspath(__file__))
TMP = os.environ.get('IREN_TMP') or HERE
sys.path.insert(0, HERE)
sys.path.insert(0, TMP)
import make_packs as mp  # noqa: E402

CHUNKS = ['C0', 'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7']
ROMAN = {1: 'I', 2: 'II', 3: 'III', 4: 'IV', 5: 'V'}
ROMAN_GR = {1: 'Α΄', 2: 'Β΄', 3: 'Γ΄', 4: 'Δ΄', 5: 'Ε΄'}

BLOCKS = {b['id']: b for b in mp.blocks}
SKIP = {'grc': {158, 159, 160}}


def is_src(b):
    if b['k'] != 'p':
        return False
    t = re.sub(r'<[^>]+>', '', b['html']).strip()
    return t.startswith('(') and ('<a ' in b['html'] or t.startswith('(источник'))


def load_out(lang):
    data = {}
    for c in CHUNKS:
        path = os.path.join(TMP, 'out', lang, f'{c}.json')
        if not os.path.exists(path):
            continue
        d = json.load(open(path, encoding='utf-8'))
        for item in d.get('blocks', []):
            item['_chunk'] = c
            data[item['id']] = item
    return data


def find_phrase(text, phrase, occurrence=None):
    positions = []
    start = 0
    while True:
        i = text.find(phrase, start)
        if i < 0:
            break
        positions.append(i)
        start = i + 1
    if not positions:
        raise ValueError(f'выделение не найдено: {phrase[:60]!r}')
    if occurrence:
        if occurrence > len(positions):
            raise ValueError(f'нет вхождения {occurrence}: {phrase[:60]!r}')
        return positions[occurrence - 1]
    return positions[0]


def quote_spans(text, marks):
    spans = []
    for m in marks:
        tag, val = m[0], m[1]
        if val == 'WHOLE':
            spans.append((0, len(text), tag))
        else:
            occ = m[2] if len(m) > 2 else None
            st = find_phrase(text, val, occ)
            spans.append((st, st + len(val), tag))
    return spans


def render_spans(text, spans, lo=0, hi=None):
    """Отрисовка куска text[lo:hi] с учётом выделений (абсолютные смещения)."""
    if hi is None:
        hi = len(text)
    local = []
    for st, en, tag in spans:
        a, b = max(st, lo), min(en, hi)
        if b > a:
            local.append((a, b, tag))
    local.sort(key=lambda s: (s[0], -s[1]))
    out = []
    pos = lo
    stack = []
    for st, en, tag in local:
        if st < pos:
            raise ValueError(f'пересечение выделений: {tag} @{st}')
        while stack and stack[-1][0] <= st:
            e, tagc = stack.pop()
            out.append(H.escape(text[pos:e], quote=False))
            out.append(f'</{tagc}>')
            pos = e
        out.append(H.escape(text[pos:st], quote=False))
        out.append(f'<{tag}>')
        stack.append((en, tag))
        pos = st
    while stack:
        e, tagc = stack.pop()
        out.append(H.escape(text[pos:e], quote=False))
        out.append(f'</{tagc}>')
        pos = e
    out.append(H.escape(text[pos:hi], quote=False))
    return ''.join(out)


def paragraph_ranges(text):
    """Разбить цитату на абзацы: по номерам пунктов и по маркерам пропуска «…»."""
    cuts = set()
    for m in re.finditer(r'(?<=[.!?;:»"])\s+(?=\d{1,3}\.\s+[A-Za-z\u0391-\u03c9\u1f00-\u1fff])', text):
        cuts.add(m.end())
    for m in re.finditer(r'\s…\s', text):
        cuts.add(m.end())
    bounds = [0] + sorted(cuts) + [len(text)]
    ranges = []
    for a, b in zip(bounds, bounds[1:]):
        if not text[a:b].strip():
            continue
        # сдвинуть границы на непробельные края
        while a < b and text[a].isspace():
            a += 1
        while b > a and text[b - 1].isspace():
            b -= 1
        if b > a:
            ranges.append((a, b))
    # слишком длинные абзацы (нет нумерации в собственном переводе) дробим по предложениям
    result = []
    for a, b in ranges or [(0, len(text))]:
        if b - a <= 1300:
            result.append((a, b))
            continue
        ends = [m.end() for m in re.finditer(r'(?<=[.!?·;])\s+', text[a:b])]
        cut = a
        last = a
        for e in ends:
            e += a
            if e - cut >= 700:
                result.append((cut, e))
                cut = e
            last = e
        if cut < b:
            result.append((cut, b))
    return result or [(0, len(text))]


def render_paragraphs(text, marks):
    spans = quote_spans(text, marks)
    return ''.join(f'<p>{render_spans(text, spans, a, b)}</p>' for a, b in paragraph_ranges(text))


def label_for(lang, work, chapters):
    ch = chapters[0] if chapters else None
    rng = ''
    if len(chapters) > 1:
        rng = f'chs. {chapters[0]}–{chapters[-1]}' if lang == 'en' else f'κεφ. {chapters[0]}–{chapters[-1]}'
    if work.startswith('b'):
        book = int(work[1])
        if lang == 'en':
            part = rng or f'ch. {ch}'
            return f'Against Heresies, Book {ROMAN[book]}, {part}'
        part = rng or f'κεφ. {ch}'
        return f'Κατὰ αἱρέσεων, βιβλ. {ROMAN_GR[book]}, {part}'
    if work == 'frag':
        return f'Fragments, {ch}' if lang == 'en' else f'Θραύσματα, {ch}'
    if work == 'dem':
        return (f'The Demonstration of the Apostolic Preaching, {ch}' if lang == 'en'
                else f'Δοκίμιον τῆς ἀποστολικῆς κηρύξεως, {ch}')
    if work == 'justin_dial':
        return (f'Justin, Dialogue with Trypho, {ch}' if lang == 'en'
                else f'Ἰουστῖνος, Διάλογος πρὸς Τρύφωνα, {ch}')
    if work == 'justin_apol1':
        return (f'Justin, First Apology, {ch}' if lang == 'en'
                else f'Ἰουστῖνος, Ἀπολογία 1, {ch}')
    if work == 'polycarp':
        return (f'The Martyrdom of Polycarp, {ch}' if lang == 'en'
                else f'Μαρτύριον τοῦ ἁγίου Πολυκάρπου, {ch}')
    raise ValueError(work)


LANG_LABEL = {'en': ' (Latin)', 'grc': ' (λατ.)'}


def la_anchor(work, chapters):
    if not chapters:
        return None
    try:
        chs = mp.load_work('la', work)
    except KeyError:
        return None
    num = chapters[0]
    for c in chs:
        m = re.match(r'^\s*(\d+)', c['title'])
        if m and int(m.group(1)) == num:
            return c['anchor']
    return None


def source_line(lang, item):
    work = item['work']
    chapters = item.get('chapters') or []
    label = label_for(lang, work, chapters)
    src = item.get('from')
    if work == 'dem':
        return f'<p>({label})</p>'
    if lang == 'en':
        target = 'la' if src == 'latin' else 'en'
    else:
        target = {'greek': 'grc', 'latin': 'la'}.get(src)
        if target is None:
            return f'<p>({label})</p>'
    if target not in mp.PATHS or work not in mp.PATHS[target]:
        return f'<p>({label})</p>'
    if target == 'la':
        label += LANG_LABEL[lang]
        anchor = la_anchor(work, chapters)
    else:
        anchor = item.get('anchor')
    path = mp.PATHS[target][work]
    href = f'https://bibleox.com/{lang}/{target}/w/' + quote(path, safe='_-')
    if anchor:
        href += '#' + anchor
    return f'<p>(<a href="{href}">{label}</a>)</p>'


OVERRIDES = json.load(open(os.path.join(TMP, 'overrides.json'), encoding='utf-8'))

# исправления явных опечаток электронного текста ANF (оговорены в references)
FIXUPS = {
    'en': {
        49: [('dispersed through our the whole world', 'dispersed through the whole world')],
        93: [('layer', 'laver')],
        136: [('the sesame heretics', 'the same heretics')],
        147: [('in harmoniously', 'inharmoniously')],
        177: [('in harmoniously', 'inharmoniously')],
        115: [('Chaffs', 'Charis')],
        120: [("neighbour s field", "neighbour's field"), ("law:300", "law:")],
        167: [('in harmoniously', 'inharmoniously')],
        123: [('neigbbour', 'neighbour')],
    }
}


def build(lang):
    out = load_out(lang)
    parts = []
    problems = []
    for bid in sorted(BLOCKS):
        b = BLOCKS[bid]
        if bid in SKIP.get(lang, set()):
            continue
        if is_src(b):
            continue
        if b['k'] == 'hr':
            parts.append('<hr>')
            continue
        ov = OVERRIDES.get(lang, {}).get(str(bid))
        if ov is not None:
            parts.append(ov)
            continue
        item = out.get(bid)
        if item is None:
            problems.append(f'нет блока {bid}')
            continue
        if b['k'] == 'quote':
            text = item['text'].replace('∆', 'Δ')
            marks = [[m[0], m[1].replace('∆', 'Δ')] + list(m[2:]) for m in (item.get('marks') or [])]
            for old, new in FIXUPS.get(lang, {}).get(bid, []):
                text = text.replace(old, new)
                for m in marks:
                    if m[1] != 'WHOLE':
                        m[1] = m[1].replace(old, new)
            try:
                inner = render_paragraphs(text, marks)
            except Exception as e:  # noqa: BLE001
                problems.append(f'блок {bid}: {e}')
                inner = f'<p>{H.escape(text, quote=False)}</p>'
            parts.append(f'<blockquote>{inner}</blockquote>')
            parts.append(source_line(lang, item))
        else:
            parts.append(item['html'])
    body = ''.join(parts)
    return body, problems, out


def check(lang, body, out):
    problems = []
    if re.search(r'[А-Яа-яЁё]', body):
        idx = re.search(r'[А-Яа-яЁё]', body).start()
        problems.append('кириллица: ' + re.sub('<[^>]+>', '', body[idx - 80:idx + 80]))
    # число цитат
    nq_ru = sum(1 for b in BLOCKS.values() if b['k'] == 'quote') - len(SKIP.get(lang, set()) & {b['id'] for b in BLOCKS.values() if b['k'] == 'quote'})
    nq = body.count('<blockquote>')
    if nq != nq_ru:
        problems.append(f'цитат {nq}, ожидалось {nq_ru}')
    # дословность
    for bid, item in out.items():
        if item['k'] != 'quote':
            continue
        text = item['text']
        src = item.get('from')
        work = item['work']
        if src in ('anf', 'greek'):
            corpus_lang = 'en' if src == 'anf' else 'grc'
            chs = mp.load_work(corpus_lang, work)
            hay = clean(' '.join(p['text'] for c in chs for p in c['paras']))
            for fr in fragments(text) or [text]:
                if clean(fr) not in hay:
                    problems.append(f'цитата {bid}: кусок не найден дословно в {corpus_lang}/{work}')
    return problems


ELLIPSIS = ['<…>', '<...>', '…', '...']


def fragments(text):
    parts = re.split(r'\s*(?:<…>|<...>|…|\.\.\.)\s*', text)
    return [p for p in (x.strip() for x in parts) if len(p) > 2]


def clean(s):
    s = s.replace('∆', 'Δ')
    s = re.sub(r'\[\d+\]', '', norm_ws(s))
    return s.replace('[', '').replace(']', '')


def norm_ws(s):
    s = unicodedata.normalize('NFC', s)
    s = s.replace('’', "'").replace('‘', "'").replace('«', '"').replace('»', '"')
    s = s.replace('–', '-').replace('—', '-')
    return ' '.join(s.split())


def main():
    lang = sys.argv[1]
    body, problems, out = build(lang)
    problems += check(lang, body, out)
    os.makedirs(os.path.join(TMP, 'build'), exist_ok=True)
    open(os.path.join(TMP, 'build', f'{lang}_body.html'), 'w', encoding='utf-8').write(body)
    print(f'{lang}: {len(body)} байт, блоков в ответах {len(out)}')
    for p in problems:
        print('  !', p)
    own = [(b, i['work'], i.get('from')) for b, i in out.items() if i['k'] == 'quote' and i.get('from') in ('latin', 'russian')]
    if own:
        print('  свои переводы цитат:', own)


if __name__ == '__main__':
    main()
