#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Сборка db/translations/grc/justin_author.yml из gr_body.html + my_parts."""
import os, sys, json

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)
import my_parts  # noqa: E402

body = open(os.path.join(HERE, 'gr_body.html'), encoding='utf-8').read().strip()
assert '\n' not in body, 'body должен быть одной строкой'

out = [
    '# Иустин Философ (ru 389) -> греческая (grc) страница автора.',
    '# Собирается из tmp/justin_gr/build_gr.py; цитаты — греческий оригинал (Ἀπολογία 1/2, Διάλογος).',
    '# Загрузка: bin/rails pages:import_translations FILE=db/translations/grc/justin_author.yml'
    ' [DRY_RUN=1] [PUBLISH=1]',
    'lang: grc',
    'list: church_writers_grc',
    'pages:',
    '  - src: Иустин_Философ_мученик',
    '    path: Ιουστίνος-ο-Φιλόσοφος-Μάρτυς',
    f'    title: {json.dumps(my_parts.TITLE, ensure_ascii=False)}',
    f'    title_sub: {json.dumps(my_parts.TITLE_SUB, ensure_ascii=False)}',
    f'    meta_desc: {json.dumps(my_parts.META_DESC, ensure_ascii=False)}',
    '    update: true',
    '    body: |-',
    '      ' + body,
    '    references: |-',
    '      ' + my_parts.REFERENCES.strip(),
    '',
]
path = os.path.join(ROOT, 'db', 'translations', 'grc', 'justin_author.yml')
os.makedirs(os.path.dirname(path), exist_ok=True)
open(path, 'w', encoding='utf-8').write('\n'.join(out))
print('->', path, os.path.getsize(path))
