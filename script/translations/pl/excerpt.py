# Фрагменты из трудов по номерам книг и глав (Иларий, De Trinitate и т. п.).
#
#   python3 script/translations/pl/excerpt.py MANIFEST.json
#
# Манифест:
#   source: путь к прогнанному тому
#   out: каталог для фрагментов
#   works:
#     - path: Hil_De_Trinitate_Fragmenta
#       work: "SANCTI HILARII PICTAVENSIS EPISCOPI DE TRINITATE LIBRI DUODECIM"
#       title: ...
#       sections:
#         - title: "Fragmenta I, 1–13"      # заголовок h2
#           book: 1
#           chapters: [1, 2, ..., 13]       # или from: 1, to: 13
#
# Текст глав в Migne: «1. Краткое резюме. ---Сам текст главы…»; резюме отрезается,
# остаётся «1. Текст главы…».

import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import extract  # noqa: E402

BOOKS = ['PRIMUS', 'SECUNDUS', 'TERTIUS', 'QUARTUS', 'QUINTUS', 'SEXTUS', 'SEPTIMUS',
         'OCTAVUS', 'NONUS', 'DECIMUS', 'UNDECIMUS', 'DUODECIMUS', 'DECIMUS TERTIUS']


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    m = json.load(open(sys.argv[1], encoding='utf-8'))
    blocks = extract.parse_blocks(open(m['source'], encoding='utf-8').read())
    os.makedirs(m['out'], exist_ok=True)

    for work in m['works']:
        # границы труда
        start = next(i for i, (tag, txt, _) in enumerate(blocks)
                     if tag != 'p' and extract.clean_heading(txt).startswith(work['work']))
        end = work.get('end')
        stop = next((i for i in range(start + 1, len(blocks))
                     if blocks[i][0] != 'p' and extract.clean_heading(blocks[i][1]).startswith(end)), len(blocks)) if end else len(blocks)

        # книги и главы: {book: {chapter: text}}
        chapters, book, cur_chapter, cur_text = {}, 0, None, []

        def flush():
            nonlocal cur_chapter, cur_text
            if cur_chapter is not None and book:
                chapters.setdefault(book, {})[cur_chapter] = ' '.join(cur_text).strip()
            cur_chapter, cur_text = None, []

        for tag, txt, raw in blocks[start:stop]:
            if tag != 'p':
                h = extract.clean_heading(txt)
                if re.match(r'^LIBER\b', h):
                    flush()
                    book = next((n + 1 for n, b in enumerate(BOOKS) if re.search(r'\b' + b + r'\b', h)), book)
                continue
            p = extract.clean_paragraph(txt)
            p = re.sub(r'^(?:\[PL[\d.]+[A-Z]?\]\s*)+', '', p)      # маркеры столбцов
            p = re.sub(r'^\d{1,4}\s+(?=\d{1,3}\.\s)', '', p)        # номер страницы перед главой
            mt = re.match(r'^(\d{1,3})\.\s*(.*)$', p)
            if mt and (cur_chapter is None or int(mt.group(1)) == cur_chapter + 1 or int(mt.group(1)) > cur_chapter):
                flush()
                cur_chapter = int(mt.group(1))
                text = mt.group(2)
                text = re.sub(r'^.*?---\s*', '', text, count=1)   # срезать резюме главы
                cur_text = [text]
            elif cur_chapter is not None:
                cur_text.append(p)
        flush()

        parts, stats = [], 0
        for sec in work['sections']:
            nums = sec.get('chapters')
            if not nums:
                nums = list(range(sec.get('from', 1), sec.get('to', sec.get('from', 1)) + 1))
            if sec.get('title'):
                parts.append(f"<h2>{sec['title']}</h2>")
            for n in nums:
                text = chapters.get(sec['book'], {}).get(n)
                if not text:
                    print(f"!! {work['path']}: нет книги {sec['book']} главы {n}")
                    continue
                parts.append(f'<p>{n}. {text}</p>')
                stats += len(text)
        body = '\n'.join(parts)
        open(os.path.join(m['out'], work['path'] + '.html'), 'w', encoding='utf-8').write(body + '\n')
        json.dump({'chars': stats, 'paragraphs': len(parts), 'h2': sum(1 for x in parts if x.startswith('<h2>'))},
                  open(os.path.join(m['out'], work['path'] + '.json'), 'w', encoding='utf-8'))
        print(f"{work['path']}: {stats} симв, частей {len(parts)}")


if __name__ == '__main__':
    main()
