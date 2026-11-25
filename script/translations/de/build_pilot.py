#!/usr/bin/env python3
"""Собирает YAML для немецкой партии 1 (Климент, Игнатий, Поликарп).

Тексты трудов — из tmp/de_bkv/out (см. bkv_epub.py), страницы авторов —
script/translations/de/authors/*.html, мученичество Поликарпа —
script/translations/de/works/martyrdom.html (свой перевод, BKV онлайн обрезан).

Запуск: python3 script/translations/de/build_pilot.py
"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
OUT = os.path.join(ROOT, 'tmp', 'de_bkv', 'out')
DB = os.path.join(ROOT, 'db', 'translations', 'de')
AUTHORS = os.path.join(ROOT, 'script', 'translations', 'de', 'authors')
WORKS = os.path.join(ROOT, 'script', 'translations', 'de', 'works')

BKV_ZELLER = ('Übersetzung von Franz Zeller, <em>Die Apostolischen Väter</em> '
              '(Bibliothek der Kirchenväter, 1. Reihe, Bd. 35), München 1918')


def read(name):
    with open(os.path.join(OUT, name), encoding='utf-8') as f:
        return f.read().strip()


def work_body(lead, html, source):
    html = re.sub(r'\s*<h2>', '\n<h2>', html).strip()
    parts = [part.strip() for part in (lead, html) if part.strip()]
    return '%s\n\n<hr>\n\n<p><strong>Quelle:</strong> %s</p>' % ('\n\n'.join(parts), source)


def author_body(name):
    with open(os.path.join(AUTHORS, name), encoding='utf-8') as f:
        return f.read().strip()


def bkv_source(pages, link):
    return '%s, S. %s. Text nach <a href="%s">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.' % (
        BKV_ZELLER, pages, link)


def yaml_quoted(value):
    return json.dumps(value, ensure_ascii=False)


def yaml_block(text, indent=6):
    return '\n'.join(((' ' * indent) + line) if line.strip() else '' for line in text.split('\n'))


def page_yaml(page, first=False):
    lines = []
    lines.append('  - src: %s' % yaml_quoted(page['src']))
    if first:
        lines.append('    # page_type и edit_mode наследуются от русской страницы-оригинала')
    lines.append('    path: %s' % yaml_quoted(page['path']))
    lines.append('    title: %s' % yaml_quoted(page['title']))
    if page.get('title_sub'):
        lines.append('    title_sub: %s' % yaml_quoted(page['title_sub']))
    lines.append('    meta_desc: %s' % yaml_quoted(page['meta_desc']))
    if page.get('menu'):
        menu = page['menu']
        parts = ['parent: %s' % yaml_quoted(menu['parent']), 'title: %s' % yaml_quoted(menu['title'])]
        if menu.get('priority') is not None:
            parts.append('priority: %d' % menu['priority'])
        lines.append('    menu: { %s }' % ', '.join(parts))
    lines.append('    update: true')
    lines.append('    body: |-')
    lines.append(yaml_block(page['body']))
    if page.get('references'):
        lines.append('    references: |-')
        lines.append(yaml_block(page['references']))
    return '\n'.join(lines)


def write_yaml(path, header, folders, pages):
    lines = ['# ' + header, '# Сборка: script/translations/de/build_pilot.py', '', 'lang: de', 'list: Kirchenvaeter']
    if folders:
        lines.append('folders:')
        for folder in folders:
            lines.append('  - { path: %s, priority: %d }' % (yaml_quoted(folder['path']), folder['priority']))
    lines.append('pages:')
    lines.append('')
    body = '\n\n'.join(page_yaml(p, first=(i == 0)) for i, p in enumerate(pages))
    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n' + body + '\n')
    print('написан', os.path.relpath(path, ROOT), '—', len(pages), 'страниц', os.path.getsize(path), 'байт')


def main():
    os.makedirs(DB, exist_ok=True)
    greek = 'https://bibleox.com/de/grc/w/'

    klemens = {
        'src': 'Климент_Римский',
        'path': 'Klemens_von_Rom',
        'title': 'Klemens von Rom, 1. Jh.',
        'title_sub': 'Hieromärtyrer († um 101), Bischof von Rom, Schüler der Apostel',
        'meta_desc': 'Klemens von Rom, Hieromärtyrer, Bischof von Rom, einer der Männer der apostolischen Zeit († um 101).',
        'menu': {'parent': '1. Jahrhundert', 'title': 'Klemens von Rom', 'priority': 1},
        'body': author_body('klemens.html'),
    }
    klemens_works = [
        {
            'src': 'КлРим_Кор1',
            'path': 'KlemRm_Kor1',
            'title': 'Erster Brief an die Korinther',
            'meta_desc': 'Erster Brief des Klemens von Rom an die Gemeinde von Korinth (um 96–97), deutsche Übersetzung von Franz Zeller (1918).',
            'menu': {'parent': '1. Jahrhundert/Klemens von Rom', 'title': 'Erster Brief an die Korinther', 'priority': 1},
            'body': work_body(
                '<p><em>Der erste Brief des Klemens von Rom an die Gemeinde von Korinth (um 96–97).</em></p>',
                read('clem1.html'),
                bkv_source('25–69', 'https://bkv.unifr.ch/works/cpg-1001/versions/clem-1clem-bkv')),
        },
        {
            'src': 'КлРим_Кор2',
            'path': 'KlemRm_Kor2',
            'title': 'Zweiter Brief an die Korinther',
            'meta_desc': 'Der dem Klemens von Rom zugeschriebene zweite Brief an die Korinther, eine Homilie aus dem 2. Jahrhundert, deutsch von Franz Zeller (1918).',
            'menu': {'parent': '1. Jahrhundert/Klemens von Rom', 'title': 'Zweiter Brief an die Korinther', 'priority': 2},
            'body': work_body(
                '<p><em>Der dem Klemens von Rom zugeschriebene zweite Brief an die Korinther – eine Homilie aus dem 2. Jahrhundert.</em></p>',
                read('clem2.html'),
                bkv_source('294–307', 'https://bkv.unifr.ch/works/cpg-1003/versions/zweiter-brief-des-klemens-an-die-korinther-bkv')),
        },
    ]

    ignatius = {
        'src': 'Игнатий_Антиохийский',
        'path': 'Ignatius_von_Antiochien',
        'title': 'Ignatius von Antiochien, 1. Jh.',
        'title_sub': 'Hieromärtyrer (um 35–107), Bischof von Antiochien, Gottesträger',
        'meta_desc': 'Hieromärtyrer (um 35–107), Bischof von Antiochien.',
        'menu': {'parent': '1. Jahrhundert', 'title': 'Ignatius von Antiochien', 'priority': 2},
        'body': author_body('ignatius.html'),
        'references': '<ol><li><p><a href="https://bibleox.com/de/de/w/IgnAnt_Rom#HH-4">Ignatius von Antiochien, Brief an die Römer, Kap. 4, 3</a></p></li></ol>',
    }
    ign_links = [
        ('ИгнАн_Еф', 'IgnAnt_Eph', 'An die Epheser', 'ign-ignatius-an-die-epheser', 1),
        ('ИгнАн_Мг', 'IgnAnt_Mag', 'An die Magnesier', 'ign-ignatius-an-die-magnesier', 2),
        ('ИгнАн_Тр', 'IgnAnt_Trall', 'An die Trallianer', 'ign-ignatius-an-die-trallianer', 3),
        ('ИгнАн_Рим', 'IgnAnt_Rom', 'An die Römer', 'ign-ignatius-an-die-r-mer', 4),
        ('ИгнАн_Фл', 'IgnAnt_Philad', 'An die Philadelphier', 'ign-ignatius-an-die-philadelphier', 5),
        ('ИгнАн_См', 'IgnAnt_Smyrn', 'An die Smyrnäer', 'ign-ignatius-an-die-smyrn-er', 6),
        ('ИгнАн_Пк', 'IgnAnt_Pol', 'An Polykarp', 'ign-ignatius-an-polykarp', 7),
    ]
    ign_works = []
    for src, path, title, key, priority in ign_links:
        ign_works.append({
            'src': src,
            'path': path,
            'title': title,
            'meta_desc': '%s des Ignatius von Antiochien, deutsche Übersetzung von Franz Zeller (1918).' % title,
            'menu': {'parent': '1. Jahrhundert/Ignatius von Antiochien', 'title': title, 'priority': priority},
            'body': work_body(
                '<p><em>Ignatius von Antiochien, %s.</em></p>' % title,
                read(key + '.html'),
                bkv_source('117–156', 'https://bkv.unifr.ch/works/cpg-1025/versions/die-sieben-briefe-des-ignatius-von-antiochien-bkv')),
        })

    polykarp = {
        'src': 'Поликарп_Смирнский',
        'path': 'Polykarp_von_Smyrna',
        'title': 'Polykarp von Smyrna, 1.–2. Jh.',
        'title_sub': 'Hieromärtyrer (69–155), Bischof von Smyrna, Schüler des Apostels Johannes',
        'meta_desc': 'Polykarp, Bischof von Smyrna, Hieromärtyrer (69–155), Schüler des Johannes des Theologen.',
        'menu': {'parent': '2. Jahrhundert', 'title': 'Polykarp von Smyrna', 'priority': 1},
        'body': author_body('polykarp.html'),
    }
    with open(os.path.join(WORKS, 'martyrdom.html'), encoding='utf-8') as f:
        martyrdom_html = f.read().strip()
    polyk_works = [
        {
            'src': 'ПлкСм_Фл',
            'path': 'PlkSm_Phil',
            'title': 'An die Philipper',
            'meta_desc': 'Brief des heiligen Polykarp von Smyrna an die Gemeinde von Philippi, deutsche Übersetzung von Franz Zeller (1918).',
            'menu': {'parent': '2. Jahrhundert/Polykarp von Smyrna', 'title': 'An die Philipper', 'priority': 1},
            'body': work_body(
                '<p><em>Brief des heiligen Polykarp von Smyrna an die Gemeinde von Philippi.</em></p>',
                read('polyk.html'),
                bkv_source('163–170', 'https://bkv.unifr.ch/works/cpg-1040/versions/der-brief-des-polykarp-von-smyrna-an-die-gemeinde-von-philippi-bkv')),
        },
        {
            'src': 'окружное-послание-Церкви-Смирнской-о-Поликарпе',
            'path': 'PlkSm_Martyr',
            'title': 'Martyrium des heiligen Polykarp',
            'meta_desc': 'Rundbrief der Kirche von Smyrna über das Martyrium des heiligen Polykarp, Bischofs von Smyrna († um 155).',
            'menu': {'parent': '2. Jahrhundert/Polykarp von Smyrna', 'title': 'Martyrium des heiligen Polykarp', 'priority': 2},
            'body': work_body(
                '',
                martyrdom_html,
                'Übersetzung aus dem Griechischen: Bibleox. Der griechische Text: '
                '<a href="https://bibleox.com/de/grc/w/%CE%9C%CE%B1%CF%81%CF%84%CF%8D%CF%81%CE%B9%CE%BF_%CF%84%CE%BF%CF%85_%CE%91%CE%B3%CE%AF%CE%BF%CF%85_%CE%A0%CE%BF%CE%BB%CF%85%CE%BA%CE%AC%CF%81%CF%80%CE%BF%CF%85_%CE%95%CF%80%CE%B9%CF%83%CE%BA%CF%8C%CF%80%CE%BF%CF%85_%CE%A3%CE%BC%CF%8D%CF%81%CE%BD%CE%B7%CF%82">Μαρτύριο του Αγίου Πολυκάρπου</a>.'),
        },
    ]

    write_yaml(
        os.path.join(DB, 'kl_00.yml'),
        'Климент Римский: автор и два послания (партия 1, немецкая библиотека)',
        [{'path': '1. Jahrhundert', 'priority': 1}, {'path': '2. Jahrhundert', 'priority': 2}],
        [klemens] + klemens_works)
    write_yaml(
        os.path.join(DB, 'ig_00.yml'),
        'Игнатий Богоносец: автор и семь писем (партия 1, немецкая библиотека)',
        [], [ignatius] + ign_works)
    write_yaml(
        os.path.join(DB, 'pl_00.yml'),
        'Поликарп Смирнский: автор, послание и мученичество (партия 1, немецкая библиотека)',
        [], [polykarp] + polyk_works)


if __name__ == '__main__':
    main()
