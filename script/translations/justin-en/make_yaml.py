#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Сборка db/translations/en/justin_author.yml из en_body.html + refs.py."""
import os, sys, json

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)
import refs  # noqa: E402

body = open(os.path.join(HERE, 'en_body.html'), encoding='utf-8').read().strip()
assert '\n' not in body, 'body должен быть одной строкой'

out = [
    '# Иустин Философ (ru 389) -> EN-страница автора. Собирается из tmp/justin_en/build_en.py',
    '# Загрузка: bin/rails pages:import_translations FILE=db/translations/en/justin_author.yml'
    ' [DRY_RUN=1] [PUBLISH=1]',
    'lang: en',
    'list: q-saints-en',
    'pages:',
    '  - src: Иустин_Философ_мученик',
    '    path: Justin-the-Philosopher-Martyr',
    f'    title: {json.dumps(refs.TITLE, ensure_ascii=False)}',
    f'    title_sub: {json.dumps(refs.TITLE_SUB, ensure_ascii=False)}',
    f'    meta_desc: {json.dumps(refs.META_DESC, ensure_ascii=False)}',
    f'    menu: {{ title: {json.dumps(refs.MENU_TITLE, ensure_ascii=False)} }}',
    '    update: true',
    '    body: |-',
    '      ' + body,
    '    references: |-',
    '      ' + refs.REFERENCES.strip(),
    '',
]
path = os.path.join(ROOT, 'db', 'translations', 'en', 'justin_author.yml')
open(path, 'w', encoding='utf-8').write('\n'.join(out))
print('->', path, os.path.getsize(path))

try:
    import yaml
except ImportError:
    print('PyYAML нет — проверка пропущена')
else:
    d = yaml.safe_load(open(path, encoding='utf-8'))
    p = d['pages'][0]
    print('keys:', sorted(p))
    print('title:', p['title'])
    print('body len:', len(p['body']))
    assert p['body'] == body, 'body не совпал после разбора YAML'
    assert p['references'].strip() == refs.REFERENCES.strip()
    print('YAML OK')
