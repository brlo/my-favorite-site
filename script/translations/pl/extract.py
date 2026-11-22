# Извлечение трудов из прогнанного тома Patrologia Latina (azbyka) в чистые HTML-фрагменты.
#
#   python3 script/translations/pl/extract.py extract MANIFEST.json
#
# Вход — HTML тома, уже прогнанный через 1_replace_gif2greek.py, 2_remove_notes.py,
# 3_replace_cols.py (лежат у автора в ~/Desktop/Библеокс/PL, результат — greek_replaced/).
# Маркеры столбцов там уже в виде [PL4.463A].
#
# Манифест — JSON (PyYAML в системном питоне нет):
#   volume: 4
#   source: /path/to/greek_replaced/PL4.html
#   out: tmp/pl/4
#   works:
#     - start: "LIBER DE LAPSIS"          # заголовок труда в Migne (начало диапазона)
#       end: "LIBER DE UNITATE ECCLESIAE" # следующий труд (null — до конца тома)
#       path: CpCr_De_Lapsis
#       title: De Lapsis
#       split: none | h2 | h2:books       # h2 — заголовки-разделы, h2:books — книги h2, главы h3
#
# Что выкидывает: ARGUMENTUM (редакторское резюме), CAPITULA (оглавления глав),
# MONITUM, NOTA, PRAEFATIO IN…, ADMONITIO, сиглы (C)/(C,G,S), ссылки на издания
# (Erasm., Pamel., Oxon. …), номера страниц, «(Vide tom. III.)», маркеры внутри заголовков.
#
# Пишет в out/: <path>.html (тело), <path>.json (статистика), report.txt.

import json
import os
import re
import sys
from html import unescape

TAG_RE = re.compile(r'<[^>]+>')
MARKER_RE = re.compile(r'\[PL(\d+)\.(\d+[A-Z]?)\]')
LEADING_NUM_RE = re.compile(r'^\s*\d{1,4}\.?\s+(?=[A-Z\[])')
SIGLA_RE = re.compile(r'\((?:[CGS](?:\s*,\s*[CGS])*)\)\*?')
EDIT_REF_RE = re.compile(
    r'\s*\((?:Erasm|Pamel|Rig|Baluz|Paris|Pariss|Oxon|Lips|Coustant|Galland|Routh|Bod|Lam|'
    r'Voss|Corb|Carn|Petav|Cellar|Morell|Manut)\.?[^()]*\)')
NOTE_RE = re.compile(r'^\[?Note:', re.I)
VID_TOM_RE = re.compile(r'\(Vid(e)?\.\s*(tom|notam)', re.I)
SECTION_NUM_RE = re.compile(r'^[IVXLC]+\.\s')


def text_of(html: str) -> str:
    """Текст блока без тегов, маркеры столбцов сохраняются."""
    s = re.sub(r'<sup>.*?</sup>', ' ', html, flags=re.S | re.I)
    s = re.sub(r'</?(?:tr|td|tbody|table|center|br)\b[^>]*>', ' ', s, flags=re.I)
    s = TAG_RE.sub('', s)
    s = unescape(s)
    s = s.replace('\u00a0', ' ').replace('\u00ad', '')
    return re.sub(r'\s+', ' ', s).strip()


def parse_blocks(html: str):
    """Блоки: (уровень, текст, сырой HTML) — сырой нужен, чтобы отрезать ARGUMENTUM внутри абзаца."""
    blocks = []
    pattern = re.compile(r'<(h[234]|p)\b[^>]*>(.*?)</\1>', re.S | re.I)
    for m in pattern.finditer(html):
        raw = m.group(2)
        txt = text_of(raw)
        if txt:
            blocks.append((m.group(1).lower(), txt, raw))
    return blocks


def cut_argumentum(raw: str) -> str:
    """Убирает резюме, начинающееся словом ARGUMENTUM: режем до конца курсивной части.

    Курсивных кусков в резюме несколько (между ними маркеры столбцов), поэтому берём
    последний </em>, до которого вне курсива осталось лишь «etc.;»/подпись редактора.
    """
    m = re.search(r'ARGUMENTUM', raw, re.I)
    if not m:
        return raw
    best = m.end()
    for em in re.finditer(r'</em>', raw[m.end():], re.I):
        end = m.end() + em.end()
        if em_metrics(raw[m.start():end])[1] <= ARGUMENTUM_OUTSIDE_MAX:
            best = end
    return raw[:m.start()] + raw[best:]


def em_metrics(raw: str):
    """Сколько букв внутри <em> и вне его. Резюме Migne набраны курсивом."""
    inside = ''.join(re.findall(r'<em\b[^>]*>(.*?)</em>', raw, re.S | re.I))
    outside = re.sub(r'<em\b[^>]*>.*?</em>', ' ', raw, flags=re.S | re.I)

    def letters(s):
        s = MARKER_RE.sub(' ', s)
        s = TAG_RE.sub(' ', s)
        return len(re.findall(r'[A-Za-z]', s))

    return letters(inside), letters(outside)


ARGUMENTUM_OUTSIDE_MAX = 40   # «PAMELIUS.», «etc.;», номера — вне курсива, но это всё ещё резюме


def is_em_only(raw: str) -> bool:
    """Почти весь абзац в курсиве -> редакторское резюме, а не текст труда."""
    inside, outside = em_metrics(raw)
    return inside > 0 and outside <= ARGUMENTUM_OUTSIDE_MAX


def clean_heading(txt: str) -> str:
    t = MARKER_RE.sub(' ', txt)
    t = re.sub(r'\bPL\d+\.\d+[A-Z]?\]?', ' ', t)
    t = SIGLA_RE.sub('', t)
    t = EDIT_REF_RE.sub('', t)
    t = LEADING_NUM_RE.sub('', t)
    t = t.strip('[] ')
    t = re.sub(r'\s*---\s*', '. ', t)
    t = re.sub(r'\.{2,}', '.', t)
    t = re.sub(r'\s+', ' ', t).strip()
    return re.sub(r'\s*\.\s*$', '', t).strip()


def clean_paragraph(txt: str) -> str:
    t = MARKER_RE.sub(lambda m: f'[PL{m.group(1)}.{m.group(2)}]', txt)
    t = VID_TOM_RE.sub(' ', t)
    t = SIGLA_RE.sub(' ', t)
    t = re.sub(r'\s+', ' ', t).strip()
    return t


# Заголовки-«переключатели»: сами в тело не идут.
EDITORIAL_HEAD = re.compile(
    r'^(ARGUMENTUM\b|MONITUM\b|CAPITULA\b|\[?NOTA\b|D\. ?P\.?\b|PRAEFATIO IN\b|'
    r'ADMONITIO\b|PROLEGOMENA\b|ELENCHUS\b|ORDO\b|INDEX\b|APPENDIX\b|SIGLIORUM\b|'
    r'OPUSCULA VULGO\b|TRACTATUS\.?$|PARS\b|DIVI THASCII\b|THASCII\b)', re.I)

EDITORIAL_TAIL = re.compile(r'\b(ADMONITIO|PRAEFATIO|MONITUM|NOTAE?)\b', re.I)

WORK_TITLE = re.compile(
    r'^(LIBER (DE|AD) |EPISTOLA AD FORTUNATUM|TESTIMONIORUM LIBRI|EPISTOLAE$)', re.I)

LETTER_RE = re.compile(r'^EPISTOLA\b')
BOOK_RE = re.compile(r'^(TESTIMONIORUM LIBER|LIBER (PRIMUS|SECUNDUS|TERTIUS|QUARTUS|QUINTUS))')
CAP_RE = re.compile(r'^CAP(UT)?\.?\s')
SKIP_PARAGRAPH = re.compile(r'^(\(?(Vid|Cf)\b|\((?:C[,\sGS]*)\)\*?\.?$|\d+$)')


def extract_work(blocks, start_idx, end_idx, path, title, split_mode, drop_em=False):
    out = []
    skipped = []
    body_started = False
    skip_until_heading = False   # CAPITULA/MONITUM/NOTA: до следующего заголовка
    arg_budget = 0                # ARGUMENTUM: срезаем не больше одного абзаца-резюме

    for pos, (tag, txt, raw) in enumerate(blocks[start_idx:end_idx]):
        if tag != 'p':
            h = clean_heading(txt)
            if not h:
                continue
            if pos == 0 and not body_started:
                body_started = True          # заголовок самого труда: страница уже названа
                continue
            if VID_TOM_RE.search(h) or NOTE_RE.match(h):
                skipped.append(h)
                continue
            if not body_started and WORK_TITLE.match(h):
                body_started = True
                skip_until_heading = False
                arg_budget = 0
                if split_mode.startswith('h2') and BOOK_RE.match(h):
                    out.append(('h', h))
                continue
            if EDITORIAL_HEAD.match(h) or EDITORIAL_TAIL.search(h):
                skipped.append(h)
                arg_budget = 1 if re.match(r'^ARGUMENTUM', h, re.I) else 0
                skip_until_heading = arg_budget == 0
                continue
            skip_until_heading = False
            arg_budget = 0
            body_started = True
            out.append(('h', h))
            continue

        if re.match(r'^(\[PL\d+\.\d+[A-Z]?\]\s*)*ARGUMENTUM\b', txt, re.I):
            raw2 = cut_argumentum(raw)
            if not raw2:
                skipped.append('ARGUMENTUM (резюме)')
                continue
            p = clean_paragraph(text_of(raw2))
        else:
            p = clean_paragraph(txt)
        if not p:
            continue
        if drop_em and is_em_only(raw) and len(p) < 600 \
                and not re.match(r'^(\[PL[^\]]*\]\s*)*\d+\.', p) \
                and not re.match(r'^(In |Apud |Item |Psalm|Evangel|Scriptum|Testimon|Cantic)', p, re.I):
            skipped.append('резюме: ' + p[:50]); continue
        if not body_started:
            skipped.append(p[:60])
            continue
        if skip_until_heading:
            skipped.append(p[:60])
            continue
        if arg_budget:
            arg_budget = 0
            if is_em_only(raw):
                skipped.append(p[:60])
                continue
        if SKIP_PARAGRAPH.match(p) or NOTE_RE.match(p):
            skipped.append(p[:60])
            continue
        if re.match(r'^(\[PL\d+\.\d+[A-Z]?\]\s*)*ARGUMENTUM\b', p):
            skipped.append(p[:60])
            continue
        # отдельный абзац-скобка редактора: «(Pontificiis tom. III. ... )»
        if re.match(r'^\(.{0,300}\)$', p):
            skipped.append(p[:60])
            continue
        out.append(('p', p))

    # ---- рендер + статистика
    html_parts = []
    stats = {'markers': 0, 'h2': 0, 'h3': 0, 'paragraphs': 0, 'chars': 0, 'empty_sections': []}
    pending_heading = None
    section_has_text = False

    for kind, text in out:
        if kind == 'p':
            pending_heading = None
            stats['markers'] += len(MARKER_RE.findall(text))
            stats['paragraphs'] += 1
            html_parts.append(f'<p>{text}</p>')
            continue

        text = clean_heading(text)
        if not text:
            continue
        if pending_heading is not None:
            stats['empty_sections'].append(pending_heading)
        if LETTER_RE.match(text) or BOOK_RE.match(text):
            level = 'h2'
        elif CAP_RE.match(text):
            level = 'h3' if split_mode == 'h2:books' else 'h2'
        else:
            level = 'h2'
        pending_heading = text
        stats[level] += 1
        html_parts.append(f'<{level}>{text}</{level}>')
    if pending_heading is not None:
        stats['empty_sections'].append(pending_heading)
    while html_parts and re.match(r'<h[23]>', html_parts[-1]):
        html_parts.pop()

    html = '\n'.join(html_parts)
    stats['chars'] = len(MARKER_RE.sub('', TAG_RE.sub('', html)))
    stats['skipped'] = sorted(set(skipped))[:40]
    stats['skipped_count'] = len(skipped)
    return html, stats


def word_pattern(text: str) -> str:
    """Шаблон заголовка с допуском на теги и переносы между словами."""
    words = [re.escape(w) for w in text.split()]
    return r'[\s\S]{0,120}?'.join(words)


def extract_verses(html: str, start: str, end: str | None):
    """Труды-стихи (гимны): текст набран строками через <br>, а не абзацами."""
    i = re.search(word_pattern(start), html)
    if not i:
        return '', {'markers': 0, 'paragraphs': 0, 'chars': 0, 'h2': 0, 'h3': 0,
                    'empty_sections': [], 'skipped': [], 'skipped_count': 0}
    start_pos = i.start()
    j = re.search(word_pattern(end), html[start_pos:]) if end else None
    end_pos = start_pos + j.start() if j else len(html)
    chunk = html[start_pos:end_pos]
    out, stats = [], {'markers': 0, 'paragraphs': 0, 'chars': 0, 'h2': 0, 'h3': 0,
                      'empty_sections': [], 'skipped': [], 'skipped_count': 0}
    for m in re.finditer(r'<h4[^>]*>(.*?)</h4>((?:(?!<h4).)*)', chunk, re.S | re.I):
        head = clean_heading(text_of(m.group(1)))
        if not re.match(r'HYMNUS\b', head, re.I):
            continue
        out.append(f'<h2>{head}</h2>')
        stats['h2'] += 1
        for line in re.split(r'<br\s*/?>', m.group(2), flags=re.I):
            line = text_of(line)
            if not line:
                continue
            out.append(f'<p>{line}</p>')
    body = '\n'.join(out)
    stats['chars'] = len(TAG_RE.sub('', body))
    stats['paragraphs'] = len(out) - stats['h2']
    return body, stats


def main():
    if len(sys.argv) < 3 or sys.argv[1] != 'extract':
        sys.exit(__doc__)
    manifest = json.load(open(sys.argv[2], encoding='utf-8'))
    src = manifest['source']
    out_dir = manifest.get('out') or os.path.join('tmp/pl', str(manifest['volume']))
    os.makedirs(out_dir, exist_ok=True)

    html = open(src, encoding='utf-8').read()
    blocks = parse_blocks(html)
    print(f'{src}: блоков {len(blocks)}')

    def find_block(prefix, after=0):
        for i in range(after, len(blocks)):
            tag, txt, _raw = blocks[i]
            if tag != 'p' and re.match(prefix, clean_heading(txt)):
                return i
        return None

    report, total = [], 0
    for w in manifest['works']:
        start = find_block(w['start'])
        if start is None:
            print(f"!! не найден старт: {w['start']}")
            report.append(f"НЕ НАЙДЕН старт: {w['start']}")
            continue
        end = find_block(w['end'], start + 1) if w.get('end') else len(blocks)
        if end is None:
            print(f"!! не найден конец: {w['end']} ({w['title']}) — берём до конца тома")
            end = len(blocks)
        if w.get('verses'):
            body, stats = extract_verses(html, w['start'], w.get('end'))
        else:
            body, stats = extract_work(blocks, start, end, w['path'], w['title'], w.get('split', 'none'), bool(w.get('drop_em')))
        open(os.path.join(out_dir, w['path'] + '.html'), 'w', encoding='utf-8').write(body + '\n')
        json.dump({**stats, 'title': w['title'], 'start': w['start'], 'end': w.get('end'),
                   'blocks': [start, end]},
                  open(os.path.join(out_dir, w['path'] + '.json'), 'w', encoding='utf-8'),
                  ensure_ascii=False, indent=1)
        total += stats['chars']
        line = (f"{w['title']:<55} {stats['chars']:>7} симв  h2={stats['h2']:>3} h3={stats['h3']:>3} "
                f"p={stats['paragraphs']:>4} маркеров={stats['markers']:>4} выкинуто={stats['skipped_count']}"
                f"{'  пустых разделов: ' + str(len(stats['empty_sections'])) if stats['empty_sections'] else ''}")
        report.append(line)
        print(line)

    open(os.path.join(out_dir, 'report.txt'), 'w', encoding='utf-8').write('\n'.join(report) + '\n')
    print(f'\nвсего {total} символов (~{total/1024:.0f} КБ текста)')


if __name__ == '__main__':
    main()
