#!/usr/bin/env python3
# Сплит ru/en источников Иустина на поглавные файлы для драфт-агентов.
# ru_413 (A1), ru_414 (A2), ru_388 (Диалог), en_416/417/406 — дампы из dev-БД.
# Главы = <h2>; сноски ru ([n]) в драфт-источниках выкидываются (ja-сноски свои).
# Выход: src/<a1|a2|dialog>/<ru|en>/chNN.txt
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))

WORKS = [
    ('a1', 'ru', 'ru_413.html'),
    ('a1', 'en', 'en_416.html'),
    ('a2', 'ru', 'ru_414.html'),
    ('a2', 'en', 'en_417.html'),
    ('dialog', 'ru', 'ru_388.html'),
    ('dialog', 'en', 'en_406.html'),
]

H2 = re.compile(r'<h2[^>]*>([^<]+)</h2>')


def clean_body(body):
    """Сноски ru и обёртки параграфов в читаемый вид: параграф = строка."""
    body = re.sub(r'\[\d+\]', '', body)
    paras = re.findall(r'<p[^>]*>(.*?)</p>', body, re.S)
    paras = [re.sub(r'\s+', ' ', p).strip() for p in paras]
    return [p for p in paras if p]


for work, lang, fname in WORKS:
    raw = open(os.path.join(HERE, fname), encoding='utf-8').read()
    # позиции h2
    marks = [(m.start(), m.end(), m.group(1).strip()) for m in H2.finditer(raw)]
    outdir = os.path.join(HERE, 'src', work, lang)
    os.makedirs(outdir, exist_ok=True)
    # intro (до первого h2) — сохраняем как ch00 если непусто
    pre = raw[:marks[0][0]] if marks else ''
    pre_paras = clean_body(pre)
    idx = 0
    if pre_paras:
        idx = 0
        p = os.path.join(outdir, 'ch00.txt')
        open(p, 'w', encoding='utf-8').write('H2: (intro)\n' + '\n\n'.join(pre_paras) + '\n')
        idx = 1
    n = len(marks)
    for i, (s, e, title) in enumerate(marks):
        end = marks[i + 1][0] if i + 1 < n else len(raw)
        body = raw[e:end]
        paras = clean_body(body)
        num = i + 1
        fn = f'ch{num:02d}.txt'
        open(os.path.join(outdir, fn), 'w', encoding='utf-8').write(
            f'H2: {title}\n' + '\n\n'.join(paras) + '\n')
    print(f'{work}/{lang}: {n} глав + {"1 intro" if pre_paras else "без intro"}')
