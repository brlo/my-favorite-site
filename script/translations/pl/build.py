# Сборка страниц из фрагментов тома PL в план импорта (JSON) для script/translations/pl/import.rb.
#
#   python3 script/translations/pl/build.py script/translations/pl/authors/cyprianus.json
#
# Берёт tmp/pl/<volume>/<fragment>.html (результат extract.py), режет на части (крупные труды
# делим по книгам/группам писем), ставит заглушки для писем, которых нет в томе, считает
# диапазон столбцов по маркерам и пишет tmp/pl/<volume>/plan.json.

import json
import os
import re
import sys

MARKER_RE = re.compile(r'\[PL(\d+)\.(\d+[A-Z]?)\]')
SOURCE_TPL = ('<p><strong>Fons:</strong> Patrologia Latina, {cols} '
              '(J.-P. Migne, Parisiis 1844). Textus recognitione automata transcriptus, sine emendatione: '
              '<a href="{url}">azbyka.ru</a>.</p>')
DUBIUM_NOTE = ('<p>Hoc opusculum in Prolegomenis Patrologiae Latinae (t. 4, coll. 803-806) '
               'inter dubia sancti Cypriani opera recensetur.</p>')


def tidy(html: str) -> str:
    """Косметика OCR: пробелы перед знаками препинания, двойные пробелы, висячие пробелы."""
    html = re.sub(r'[ \t]{2,}', ' ', html)
    html = re.sub(r' +([,.;:!?])', r'\1', html)
    html = re.sub(r' +\)', ')', html)
    html = re.sub(r'\( +', '(', html)
    html = re.sub(r'\s+</p>', '</p>', html)
    html = re.sub(r'<p>\s+', '<p>', html)
    html = re.sub(r'\n{2,}', '\n', html)
    return html.strip()


FRAGMENT_NOTE = re.compile(r'^(Citat hoc fragmentum|Hoc fragmentum|Haec autem verba pertinere|'
                           r'Citatum hoc|Fragmentum istud)', re.I)
EDIT_TAIL = re.compile(r'\s*\((?:S\.\s*)?(?:Aug|Hier|Ambr|Greg|Cypr|Tert)[^)]{0,90}'
                       r'(?:l\.|lib\.|cap\.|epist\.)[^)]*\)\.?\s*$')


def clean_page(body: str) -> str:
    """Убирает редакторские примечания Migne, попавшие в тело (фрагменты, ссылки в конце)."""
    parts = re.split(r'(?=<p>)', body)
    kept = []
    for part in parts:
        m = re.match(r'<p>(.*?)</p>', part, re.S)
        if m and FRAGMENT_NOTE.match(re.sub(r'^\[PL[\d.]+[A-Z]?\]\s*', '', m.group(1))):
            continue
        kept.append(part)
    body = ''.join(kept).strip()
    # редакторская ссылка в конце последнего абзаца: «… (S. Aug., l. II …, c. 5).»
    m = re.search(r'<p>((?:(?!</p>).)*)</p>\s*$', body, re.S)
    if m and EDIT_TAIL.search(m.group(1)):
        body = body[:m.start(1)] + EDIT_TAIL.sub('', m.group(1)) + body[m.end(1):]
    return body


def marker_range(html: str):
    ms = MARKER_RE.findall(html)
    if not ms:
        return None
    return ms[0][1], ms[-1][1]


def cols_str(html: str):
    """Диапазон столбцов по каждому тому отдельно: в добранных письмах маркеры PL 3."""
    groups = {}
    for vol, num in MARKER_RE.findall(html):
        groups.setdefault(vol, []).append(num)
    if not groups:
        return 'coll. ?'
    return '; '.join(f't. {vol}, coll. {nums[0]}-{nums[-1]}' for vol, nums in groups.items())


def sections(html: str):
    """Куски, каждый начинается с <h2>; первый может быть без заголовка."""
    return [s for s in re.split(r'(?=<h2>)', html) if s.strip()]


def heading_of(section: str) -> str:
    m = re.search(r'<h2>(.*?)</h2>', section, re.S)
    return re.sub(r'<[^>]+>', '', m.group(1)).strip() if m else ''


def letter_number(heading: str):
    m = re.match(r'EPISTOLA\s+([IVXLC]+)\b', heading)
    return m.group(1) if m else None


def drop_book_heading(html: str, titles) -> str:
    for t in titles:
        html = re.sub(r'<h2>' + re.escape(t) + r'</h2>\s*', '', html, count=1)
    return html


SUPPLEMENTS = 'tmp/pl/3/supplements'


def body_text_len(part: str) -> int:
    """Сколько в куске настоящего текста (без заголовка, тегов и маркеров)."""
    after = re.sub(r'^.*?</h2>', '', part, count=1, flags=re.S)
    plain = MARKER_RE.sub(' ', re.sub(r'<[^>]+>', ' ', after))
    return len(re.findall(r'[A-Za-z]', plain))


def fill_empty_letters(html: str, sup_dir: str = SUPPLEMENTS) -> tuple[str, list[str], list[str]]:
    """Письма, у которых в томе нет текста (только заголовок/резюме): подставляем добор из
    PL 3 (если он есть) или пометку. Возвращает номера писем, оставшихся без текста."""
    out, missing, filled = [], [], []
    parts = re.split(r'(?=<h2>)', html)
    for part in parts:
        if part.strip().startswith('<h2>'):
            num = letter_number(heading_of(part))
            if num and body_text_len(part) < 80:
                sup_path = os.path.join(sup_dir, f'ep_{num}.html')
                if os.path.exists(sup_path):
                    sup = open(sup_path, encoding='utf-8').read().strip()
                    head = re.search(r'<h2>.*?</h2>', part, re.S).group(0)
                    part = head + '\n' + sup + '\n'
                    filled.append(num)
                else:
                    missing.append(num)
                    part = (part.rstrip() +
                            '\n<p><em>Textus huius epistolae in hoc volumine Migne non exhibetur '
                            '(ad tomum III remittitur, ubi etiam deest).</em></p>\n')
        out.append(part)
    if filled:
        print('добрано из PL 3:', ', '.join(filled))
    return ''.join(out), missing, filled


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    cfg = json.load(open(sys.argv[1], encoding='utf-8'))
    vol = cfg['volume']
    base = os.path.join('tmp/pl', str(vol))

    def fragment(name):
        path = os.path.join(base, name + '.html')
        if not os.path.exists(path):
            sys.exit(f'нет фрагмента {path}')
        return open(path, encoding='utf-8').read()

    pages = []
    missing_letters = []
    filled_letters = []

    for w in cfg['works']:
        src = fragment(w['fragment'])
        dubium = bool(w.get('dubium'))
        if not w.get('parts'):
            body, _miss, _fill = fill_empty_letters(src)
            filled_letters += _fill
            body = clean_page(tidy(body))
            note = SOURCE_TPL.format(cols=cols_str(body), url=cfg['source_url']) + (DUBIUM_NOTE if dubium else '')
            pages.append({'path': w['path'], 'title': w['title'], 'ru': w.get('ru'), 'folder': w['folder'],
                          'priority': w['priority'], 'body': body, 'references': note,
                          'page_type': 1, 'seo_kind': 'book', 'cols': cols_str(body)})
            continue

        secs = sections(src)
        heads = [heading_of(s) for s in secs]
        for part in w['parts']:
            if part['first'] is None:
                start = 0
            else:
                start = next(i for i, h in enumerate(heads) if h.startswith(part['first']))
            if part['last'] is None:
                end = len(secs)
            else:
                end = next(i for i, h in enumerate(heads) if h.startswith(part['last']))
            chunk = ''.join(secs[start:end])
            chunk, miss, fill = fill_empty_letters(chunk)
            missing_letters += miss
            filled_letters += fill
            body = clean_page(tidy(chunk))
            note = SOURCE_TPL.format(cols=cols_str(body), url=cfg['source_url']) + (DUBIUM_NOTE if dubium else '')
            pages.append({'path': part['path'], 'title': part['title'], 'ru': w.get('ru'), 'folder': w['folder'],
                          'priority': part['priority'], 'body': body, 'references': note,
                          'page_type': 1, 'seo_kind': 'book', 'cols': cols_str(body)})
            print(f"{part['title']:<32} {len(body)//1024:>4} КБ  coll. {cols_str(body):<12} h2={body.count('<h2>')}")

    if filled_letters:
        note = ('<p>Epistolae ' + ', '.join(filled_letters) +
                ', quibus hoc volumine Migne solum argumentum praebet, ex tomo III (PL 3) suppletae sunt.</p>')
        for p in pages:
            if p['path'].startswith('CpCr_Epistolae'):
                p['references'] += note
        print('добрано из tomo III:', ', '.join(filled_letters))

    if missing_letters:
        note = ('<p>Epistolae ' + ', '.join(missing_letters) +
                ' textum neque in hoc volumine neque in tomo III habent.</p>')
        for p in pages:
            if p['path'].startswith('CpCr_Epistolae'):
                p['references'] += note
        print('письма без текста:', ', '.join(missing_letters))

    a = cfg['author']
    author_body = open(a['body_file'], encoding='utf-8').read()
    plan = {
        'lang': cfg['lang'], 'list': cfg['list'],
        'author': {**{k: a[k] for k in ('path', 'title', 'title_sub', 'ru', 'menu_folder', 'menu_replace', 'menu_title', 'references')},
                   'body': author_body, 'page_type': 4, 'seo_kind': 'person'},
        'folders': cfg['folders'],
        'pages': pages,
    }
    out = os.path.join(base, 'plan.json')
    json.dump(plan, open(out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    total = sum(len(p['body']) for p in pages)
    print(f'\nстраниц: {len(pages)} (+ автор), текста ~{total/1024:.0f} КБ → {out}')


if __name__ == '__main__':
    main()
