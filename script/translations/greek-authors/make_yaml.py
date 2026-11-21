#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""YAML для греческих страниц Игнатия/Поликарпа."""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)

CFG = {
    'ign': {'parts': 'ign_parts', 'src': 'Игнатий_Антиохийский',
            'path': 'Ιγνάτιος_Θεοφόρος_Αντιοχείας', 'body': 'ign_body.html',
            'file': 'ignatius_author.yml'},
    'pol': {'parts': 'pol_parts', 'src': 'Поликарп_Смирнский',
            'path': 'Πολύκαρπος_Σμύρνης', 'body': 'pol_body.html',
            'file': 'polycarp_author.yml'},
}


def main(page):
    c = CFG[page]
    parts = __import__(c['parts'])
    body = open(os.path.join(HERE, c['body']), encoding='utf-8').read().strip()
    assert '\n' not in body
    out = [
        f'# {c["src"]} -> греческая (grc) страница автора.',
        '# Собирается из tmp/pages_gr/build_page.py; цитаты — греческий оригинал.',
        f'# Загрузка: bin/rails pages:import_translations FILE=db/translations/grc/{c["file"]} [DRY_RUN=1] [PUBLISH=1]',
        'lang: grc',
        'list: church_writers_grc',
        'pages:',
        f'  - src: {c["src"]}',
        f'    path: {c["path"]}',
        f'    title: {json.dumps(parts.TITLE, ensure_ascii=False)}',
        f'    title_sub: {json.dumps(parts.TITLE_SUB, ensure_ascii=False)}',
        f'    meta_desc: {json.dumps(parts.META_DESC, ensure_ascii=False)}',
        '    update: true',
        '    body: |-',
        '      ' + body,
        '    references: |-',
        '      ' + parts.REFERENCES.strip(),
        '',
    ]
    path = os.path.join(ROOT, 'db', 'translations', 'grc', c['file'])
    open(path, 'w', encoding='utf-8').write('\n'.join(out))
    print('->', path, os.path.getsize(path))


if __name__ == '__main__':
    main(sys.argv[1])
