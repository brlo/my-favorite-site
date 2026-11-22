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


SUMMARY_INLINE = re.compile(r'^(<p>)(\d{1,3})\.\s[^<]{0,400}?---\s*')


SIGLUM_RE = re.compile(r'\b(?:Lips|Pamel|Baluz|Oxon|Erasm|Rig|Lam|Bod|Voss|Coustant|Galland|'
                       r'Manut|Morell|Cellar)\.\s')


def strip_apparatus(body: str) -> str:
    """Убирает квадратные скобки с вариантами чтения (в т.ч. с вложенными маркерами столбцов)."""
    out, i = [], 0
    while i < len(body):
        if body[i] != '[':
            out.append(body[i]); i += 1; continue
        depth, j = 0, i
        while j < len(body):
            if body[j] == '[':
                depth += 1
            elif body[j] == ']':
                depth -= 1
                if depth == 0:
                    break
            j += 1
        seg = body[i:j + 1]
        if SIGLUM_RE.search(seg):
            i = j + 1
        else:
            out.append(seg); i = j + 1
    return ''.join(out)


def clean_page(body: str) -> str:
    body = strip_apparatus(body)                # варианты чтения в квадратных скобках
    # «1. Резюме главы.---Текст» -> «1. Текст»
    body = re.sub(r'(<p>)(\d{1,3})\.\s[^<]{0,400}?---\s*', r'\1\2. ', body)
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


def split_paragraphs(body: str, max_bytes: int):
    """Режет тело на куски не больше max_bytes: сначала по <h2>, внутри крупного раздела — по <p>."""
    def chunks_of(parts, limit):
        total, n = sum(len(p) for p in parts), max(2, int(sum(len(p) for p in parts) / limit) + 1)
        target = total / n
        out, cur, acc = [], [], 0
        for p in parts:
            if cur and acc + len(p) > target and len(out) < n - 1:
                out.append(''.join(cur)); cur, acc = [], 0
            cur.append(p); acc += len(p)
        if cur:
            out.append(''.join(cur))
        return out

    def merge_tiny(chunks):
        """Сливает куски без текста (один заголовок) с соседними."""
        def tlen(c):
            return len(re.sub(r'<[^>]+>', '', c).strip())
        out, pending = [], ''
        for c in chunks:
            if tlen(c) < 400:
                if out:
                    out[-1] += c
                else:
                    pending += c
                continue
            out.append(pending + c)
            pending = ''
        if pending:
            if out:
                out[-1] += pending
            else:
                out.append(pending)
        return out

    if '<h2>' in body:
        secs = [x for x in re.split(r'(?=<h2>)', body) if x.strip()]
        groups, cur, acc = [], [], 0
        for sec in secs:
            if len(sec) > max_bytes:            # отдельный раздел больше лимита — режем по абзацам
                if cur:
                    groups.append(''.join(cur)); cur, acc = [], 0
                groups += chunks_of([p for p in re.split(r'(?=<p>)', sec) if p.strip()], max_bytes)
                continue
            if cur and acc + len(sec) > max_bytes:
                groups.append(''.join(cur)); cur, acc = [], 0
            cur.append(sec); acc += len(sec)
        if cur:
            groups.append(''.join(cur))
        return merge_tiny(groups)
    return merge_tiny(chunks_of([p for p in re.split(r'(?=<p>)', body) if p.strip()], max_bytes))


def range_title(title: str, chunk: str, i: int, n: int):
    """Подпись куска: для писем — по номерам, иначе «(i/n)»."""
    text = re.sub(r'<[^>]+>', ' ', chunk)
    nums = re.findall(r'EPISTOLA\s+([IVXLC]+)\b', text)
    if len(nums) >= 2:
        first = 'I' if 'PRIMA CLASSIS' in text[:3000] else nums[0]
        return f'{title} {first}–{nums[-1]}'
    return f'{title} ({i}/{n})'

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


def fill_empty_letters(html: str, sup_dir: str | None = SUPPLEMENTS) -> tuple[str, list[str], list[str]]:
    if sup_dir is None:            # не письма этого автора: заглушки и добор не применяем
        return html, [], []
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
    # третий аргумент (или VOLUME=) — собрать план только по одному тому
    only_volume = None
    if len(sys.argv) > 2:
        only_volume = int(sys.argv[2])
    elif os.environ.get('VOLUME'):
        only_volume = int(os.environ['VOLUME'])
    if only_volume:
        cfg['works'] = [w for w in cfg['works'] if w.get('volume', cfg['volume']) == only_volume]
        cfg['volume'] = only_volume
    vol_default = cfg['volume']
    vol = vol_default
    base = os.path.join('tmp/pl', str(vol))

    def fragment(name, vol=None):
        path = os.path.join('tmp/pl', str(vol or vol_default), name + '.html')
        if not os.path.exists(path):
            sys.exit(f'нет фрагмента {path}')
        return open(path, encoding='utf-8').read()

    pages = []
    missing_letters = []
    filled_letters = []
    max_kb = cfg.get('max_kb')

    def add_page(path, title, body, priority, folder, ru, dubium, vol, limit_kb=None, no_markers=False, dubium_note=None):
        if not body.strip():
            print(f"  (пропуск пустой страницы: {title})")
            return
        note = SOURCE_TPL.format(cols=cols_str(body), url=cfg['source_url']) + ((dubium_note or DUBIUM_NOTE) if dubium else '')
        limit = (limit_kb or max_kb) and (limit_kb or max_kb) * 1024
        if limit and len(body) > limit:
            chunks = split_paragraphs(body, limit)
            for i, chunk in enumerate(chunks, 1):
                chunk_title = range_title(title, chunk, i, len(chunks))
                pages.append({'path': f'{path}_{i}', 'title': chunk_title,
                              'ru': ru, 'folder': folder, 'priority': priority,
                              'body': chunk, 'references': SOURCE_TPL.format(cols=cols_str(chunk), url=cfg['source_url']) +
                              ((dubium_note or DUBIUM_NOTE) if dubium else ''),
                              'page_type': 1, 'seo_kind': 'book', 'cols': cols_str(chunk), 'volume': vol})
                print(f"{title} ({i}/{len(chunks)})"[:60].ljust(62) + f"{len(chunk)//1024:>4} КБ")
            return
        pages.append({'path': path, 'title': title, 'ru': ru, 'folder': folder, 'priority': priority,
                      'body': body, 'references': note, 'page_type': 1, 'seo_kind': 'book',
                      'cols': cols_str(body), 'volume': vol})

    for w in cfg['works']:
        vol = w.get('volume', vol_default)
        src = fragment(w['fragment'], vol)
        dubium = bool(w.get('dubium'))
        if not w.get('parts'):
            body, _miss, _fill = fill_empty_letters(src, w.get('letters_supplement'))
            filled_letters += _fill
            body = clean_page(tidy(body))
            if w.get('cap_inline'):
                body = re.sub(r'<p>CAPUT ([IVXLC]+)\.---\s*(\d+\.\s*)?', r'<h2>CAPUT \1</h2><p>', body)
            add_page(w['path'], w['title'], body, w['priority'], w['folder'], w.get('ru'), dubium, vol, w.get('max_kb'), bool(w.get('verses')), w.get('dubium_note'))
            continue

        secs = sections(src)
        heads = [heading_of(s) for s in secs]
        prev_end = 0
        for part in w['parts']:
            if part['first'] is None:
                start = 0
            else:
                start = next(i for i, h in enumerate(heads) if i >= prev_end and h.startswith(part['first']))
            if part['last'] is None:
                end = len(secs)
            else:
                end = next(i for i, h in enumerate(heads) if i > start and h.startswith(part['last']))
            prev_end = end
            chunk = ''.join(secs[start:end])
            if len(re.sub(r'<[^>]+>', '', chunk)) < 1500:
                print(f"  (пропуск пустой части: {part['title']})")
                continue
            chunk, miss, fill = fill_empty_letters(chunk, w.get('letters_supplement'))
            missing_letters += miss
            filled_letters += fill
            body = clean_page(tidy(chunk))
            add_page(part['path'], part['title'], body, part['priority'], w['folder'],
                     part.get('ru') or w.get('ru'), dubium, vol, w.get('max_kb'), bool(w.get('verses')))
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
        'lang': cfg['lang'], 'list': cfg['list'], 'volume': only_volume or vol_default,
        'author': {**{k: a[k] for k in ('path', 'title', 'title_sub', 'ru', 'menu_folder', 'menu_replace', 'menu_title', 'references')},
                   'body': author_body, 'page_type': 4, 'seo_kind': 'person'},
        'folders': cfg['folders'],
        'pages': pages,
    }
    out = os.path.join(base, f'plan_v{only_volume}.json' if only_volume else 'plan.json')
    json.dump(plan, open(out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    total = sum(len(p['body']) for p in pages)
    print(f'\nстраниц: {len(pages)} (+ автор), текста ~{total/1024:.0f} КБ → {out}')


if __name__ == '__main__':
    main()
