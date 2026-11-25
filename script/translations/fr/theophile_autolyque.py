#!/usr/bin/env python3
"""Théophile d'Antioche, « À Autolyque » (fr): Wikisource -> YAML для сайта.

Текст — перевод М. де Женуда (Genoude), Sapia, 1838 (тот же, что в BKV),
три книги на fr.wikisource.org. Права: Genoude († 1849) — общественное
достояние; Wikisource — свободный текст.

Запуск: python3 script/translations/fr/theophile_autolyque.py
Пишет db/translations/fr/theophile.yml (импорт см. в конце вывода).
"""
import json
import os
import re
import urllib.request

from lxml import html

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
TMP = os.path.join(ROOT, 'tmp', 'fr', 'theophile')
DB = os.path.join(ROOT, 'db', 'translations', 'fr')
AUTHORS = os.path.join(ROOT, 'script', 'translations', 'fr', 'authors')
WIKI = 'https://fr.wikisource.org/wiki/Les_P%C3%A8res_de_l%E2%80%99%C3%89glise/Tome_2/'
BOOKS = [
    ('1', 'Saint_Th%C3%A9ophile_%C3%A0_Autolyque._%E2%80%94_Livre_premier'),
    ('2', 'Saint_Th%C3%A9ophile_%C3%A0_Autolyque._%E2%80%94_Livre_second'),
    ('3', 'Saint_Th%C3%A9ophile_%C3%A0_Autolyque._%E2%80%94_Livre_troisi%C3%A8me'),
]
SOURCE = ('M. de Genoude, <em>Les Pères de l’Église</em>, t. II, Sapia, 1838, p. 397 et suiv. '
          'Texte : <a href="https://fr.wikisource.org/wiki/Les_P%C3%A8res_de_l%E2%80%99%C3%89glise/Tome_2/'
          'Saint_Th%C3%A9ophile_%C3%A0_Autolyque._%E2%80%94_Livre_premier">fr.wikisource.org</a> '
          '(même traduction que la version française de la BKV).')


def fetch(url, path):
    if os.path.exists(path):
        return open(path, 'rb').read()
    req = urllib.request.Request(url, headers={'User-Agent': 'bibleox-library-import/1.0'})
    data = urllib.request.urlopen(req, timeout=30).read()
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'wb').write(data)
    return data


def inner_html(p):
    s = html.tostring(p, encoding='unicode', method='html', with_tail=False)
    m = re.fullmatch(r'<p[^>]*>(.*)</p>', s, re.S)
    inner = m.group(1) if m else re.sub(r'^<p[^>]*>|</p>$', '', s, flags=re.S)
    inner = re.sub(r'\s+', ' ', inner).strip()
    inner = re.sub(r'\s+([.,;:!?»])', r'\1', inner)
    return inner


def book_html(raw):
    doc = html.fromstring(raw)
    out = doc.xpath('//div[contains(@class,"prp-pages-output")]')[0]
    parts = []
    for el in out.xpath('./p|./h2'):
        if el.tag == 'h2':
            continue
        for span in el.xpath('.//span[contains(@class,"pagenum")]'):
            span.drop_tree()
        # пустые span от маркеров страниц и span-«coquille» (опечатки с подсказкой)
        for span in el.xpath('.//span'):
            if span.getparent() is None:
                continue
            if not ' '.join(span.text_content().split()):
                span.drop_tree()
            elif span.get('class'):
                span.drop_tag()
        text = ' '.join(el.text_content().split())
        if not text:
            continue
        parts.append('<p>%s</p>' % inner_html(el))
    return '\n'.join(parts)


def work_body():
    chunks = []
    for n, slug in BOOKS:
        raw = fetch(WIKI + slug, os.path.join(TMP, n + '.html'))
        html_book = book_html(raw)
        if n == '1':
            # в источнике у первой главы нет номера — выравниваем с II, III...
            html_book = re.sub(r'^<p>(?!I\.)', '<p>I. ', html_book, count=1)
        chunks.append('<h2>%s</h2>\n%s' % (n, html_book))
    return ('<p><em>Trois livres à Autolyque, traduction de M. de Genoude (1838).</em></p>\n\n'
            + '\n\n'.join(chunks)
            + '\n\n<hr>\n\n<p><strong>Source :</strong> %s</p>' % SOURCE)


def yaml_quoted(value):
    return json.dumps(value, ensure_ascii=False)


def yaml_block(text, indent=6):
    return '\n'.join(((' ' * indent) + line) if line.strip() else '' for line in text.split('\n'))


def page_yaml(p):
    lines = ['  - src: %s' % yaml_quoted(p['src']),
             '    path: %s' % yaml_quoted(p['path']),
             '    title: %s' % yaml_quoted(p['title'])]
    if p.get('title_sub'):
        lines.append('    title_sub: %s' % yaml_quoted(p['title_sub']))
    lines.append('    meta_desc: %s' % yaml_quoted(p['meta_desc']))
    menu = p['menu']
    parts = ['parent: %s' % yaml_quoted(menu['parent']), 'title: %s' % yaml_quoted(menu['title'])]
    if menu.get('replace'):
        parts.append('replace: %s' % yaml_quoted(menu['replace']))
    if menu.get('priority') is not None:
        parts.append('priority: %d' % menu['priority'])
    lines.append('    menu: { %s }' % ', '.join(parts))
    lines.append('    update: true')
    lines.append('    body: |-')
    lines.append(yaml_block(p['body']))
    return '\n'.join(lines)


def write_yaml(path, header, list_path, pages, folders=None):
    head = ['# ' + header, '# Сборка: script/translations/fr/theophile_autolyque.py', '',
            'lang: fr', 'list: %s' % yaml_quoted(list_path)]
    if folders:
        head.append('folders:')
        head += ['  - { path: %s, priority: %d }' % (yaml_quoted(f['path']), f['priority']) for f in folders]
    head += ['pages:', '']
    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(head) + '\n' + '\n\n'.join(page_yaml(p) for p in pages) + '\n')
    print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


def main():
    author = open(os.path.join(AUTHORS, 'theophile.html'), encoding='utf-8').read().strip()
    pages = [
        {
            'src': 'Феофил_Антиохийский',
            'path': 'Théophile_d_Antioche',
            'title': 'Théophile d’Antioche, IIe siècle',
            'title_sub': 'saint, écrivain chrétien, apologète et polémiste (†183)',
            'meta_desc': '',
            'menu': {'parent': 'IIe siècle', 'title': "Théophile d'Antioche, saint (†183)",
                     'replace': "Théophile d'Antioche, saint (†183)", 'priority': 2},
            'body': author,
        },
        {
            'src': 'Феофил-послание_к_Автолику',
            'path': 'Theophile_A_Autolyque',
            'title': 'À Autolyque',
            'title_sub': '',
            'meta_desc': 'Trois livres à Autolyque de Théophile d’Antioche, traduction de M. de Genoude (1838).',
            'menu': {'parent': 'Œuvres apologétiques', 'title': 'À Autolyque', 'priority': 1},
            'body': work_body(),
        },
    ]
    pages[1].pop('title_sub')

    os.makedirs(DB, exist_ok=True)
    write_yaml(os.path.join(DB, 'theophile_author.yml'),
               'Théophile d\'Antioche: страница автора (fr, Wikisource/Genoude 1838)',
               '4saQ_Ouvrages_des_anciens_chrétiens', [pages[0]])
    write_yaml(os.path.join(DB, 'theophile_works.yml'),
               'Théophile d\'Antioche: «À Autolyque» (fr, Wikisource/Genoude 1838)',
               'Théophile_d_Antioche', [pages[1]],
               folders=[{'path': 'Œuvres apologétiques', 'priority': 1}])


if __name__ == '__main__':
    main()
