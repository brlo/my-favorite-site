#!/usr/bin/env python3
"""Проверка JSON одного пакета: блоки, выделения, дословность, кириллица.

Запуск: python3 tmp/iren/check_chunk.py <lang> <CHUNK>
"""
import json
import os
import re
import sys
import unicodedata

HERE = os.path.dirname(os.path.abspath(__file__))
TMP = os.environ.get('IREN_TMP') or HERE
sys.path.insert(0, HERE)
sys.path.insert(0, TMP)
import make_packs as mp  # noqa: E402

CHUNKS = [('C0', 0, 46), ('C1', 47, 64), ('C2', 65, 88), ('C3', 89, 116),
          ('C4', 117, 131), ('C5', 132, 151), ('C6', 152, 178), ('C7', 179, 184)]
SKIP = {'grc': {158, 159, 160}}
COORD = {1, 2, 4, 5, 77, 180, 181}


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
    s = s.replace('–', '-').replace('—', '-').replace('\u00a0', ' ')
    return ' '.join(s.split())


def is_src(b):
    if b['k'] != 'p':
        return False
    t = re.sub(r'<[^>]+>', '', b['html']).strip()
    return t.startswith('(') and ('<a ' in b['html'] or t.startswith('(источник'))


def main():
    lang, chunk = sys.argv[1], sys.argv[2]
    start, end = next((s, e) for n, s, e in CHUNKS if n == chunk)
    ids = [i for i in range(start, end + 1)
           if i not in SKIP.get(lang, set()) and i not in COORD
           and not is_src(mp.blocks[i]) and mp.blocks[i]['k'] != 'hr']
    path = os.path.join(TMP, 'out', lang, f'{chunk}.json')
    data = json.load(open(path, encoding='utf-8'))
    got = {b['id']: b for b in data['blocks']}
    problems = []
    for i in ids:
        if i not in got:
            problems.append(f'нет блока {i}')
    for i in got:
        if i not in ids and i not in COORD:
            problems.append(f'лишний блок {i}')
    for i in ids:
        item = got.get(i)
        if not item:
            continue
        b = mp.blocks[i]
        if b['k'] == 'quote':
            text = item.get('text') or ''
            if not text.strip():
                problems.append(f'{i}: пустая цитата')
            for m in item.get('marks') or []:
                if m[1] != 'WHOLE' and text.count(m[1]) == 0:
                    problems.append(f'{i}: выделение не найдено: {m[1][:40]!r}')
            src = item.get('from')
            work = item.get('work')
            if src in ('anf', 'greek'):
                corpus_lang = 'en' if src == 'anf' else 'grc'
                try:
                    chs = mp.load_work(corpus_lang, work)
                except KeyError:
                    problems.append(f'{i}: неизвестная работа {corpus_lang}/{work}')
                    continue
                hay = clean(' '.join(p['text'] for c in chs for p in c['paras']))
                frags = fragments(text) or [text]
                for fr in frags:
                    if clean(fr) not in hay:
                        problems.append(f'{i}: кусок цитаты не найден дословно в {corpus_lang}/{work}: {fr[:60]!r}')
            if not item.get('anchor') and work != 'dem':
                problems.append(f'{i}: нет anchor')
        else:
            html = item.get('html') or ''
            if re.search(r'[А-Яа-яЁё]', html):
                problems.append(f'{i}: кириллица в html')
    if re.search(r'[А-Яа-яЁё]', json.dumps([b.get('text', '') + b.get('html', '') for b in data['blocks']], ensure_ascii=False)):
        problems.append('кириллица в текстах/цитатах')
    print(f'{lang}/{chunk}: блоков {len(got)} из {len(ids)}, проблем {len(problems)}')
    for p in problems:
        print('  !', p)
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
