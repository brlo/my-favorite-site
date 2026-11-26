#!/usr/bin/env python3
"""Сборка немецкого Иоанна Кассиана: автор + два труда (BKV)."""
import os
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
DB = os.path.join(ROOT, 'db', 'translations', 'de')
OUT = os.path.join(ROOT, 'tmp', 'de_bkv', 'out')
AUTHOR = os.path.join(ROOT, 'script', 'translations', 'de', 'authors', 'cassian.html')

SOURCES = {
    'inst': ('Von den Einrichtungen der Klöster', 'https://bkv.unifr.ch/de/works/cpl-513/versions/von-den-einrichtungen-der-kloster-bkv'),
    'inc': ('Sieben Bücher über die Menschwerdung Christi', 'https://bkv.unifr.ch/de/works/cpl-514/versions/sieben-bucher-uber-die-menschwerdung-christi-bkv'),
    'conf': ('Vierundzwanzig Unterredungen mit den Vätern', 'https://bkv.unifr.ch/de/works/cpl-512/versions/vierundzwanzig-unterredungen-mit-den-vatern-bkv'),
}


sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402


def conf_parts():
    with zipfile.ZipFile(os.path.join(ROOT, 'tmp', 'de_bkv', 'cas_conf.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    chapters = []
    for heading in doc.xpath('//h2'):
        title = ''.join(heading.itertext()).strip()
        if title.startswith('Vorwort'):
            continue
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        chapters.append((title, body))
    def render(items, offset):
        return ''.join(f'<h2>{offset + i}</h2><p><strong>{title}</strong></p>{body}'
                       for i, (title, body) in enumerate(items))
    return render(chapters[:12], 1), render(chapters[12:], 13)


def sections(key):
    with zipfile.ZipFile(os.path.join(ROOT, 'tmp', 'de_bkv', 'cas_' + key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for i, heading in enumerate(doc.xpath('//h2'), 1):
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        parts.append(f'<h2>{i}</h2>{body}')
    return ''.join(parts)


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def source(key):
    title, url = SOURCES[key]
    return (f'<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>{title}</em> '
            f'(Bibliothek der Kirchenväter). Text nach <a href="{url}">bkv.unifr.ch</a>; '
            f'die Anmerkungen der Ausgabe sind weggelassen.</p>')


def page(src, path, title, key, parent, priority, body=None):
    content = body if body is not None else open(os.path.join(OUT, 'cas_' + key + '.html'), encoding='utf-8').read().strip()
    body = (f'<p><em>{title} (Bibliothek der Kirchenväter).</em></p>' + content)
    return f'''  - src: "{src}"
    path: "{path}"
    title: "{title}"
    menu: {{ parent: "{parent}", title: "{title}", priority: {priority} }}
    update: true
    body: |-
{block(body)}
    references: |-
{block(source(key))}
'''


def main():
    conf1, conf2 = conf_parts()
    author_html = open(AUTHOR, encoding='utf-8').read().strip()
    author = f'''# Иоанн Кассиан: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_cassian.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "49Rq_Иоанн_Кассиан_Римлянин_IVV_вв"
    path: "Johannes_Cassianus"
    title: "Johannes Cassianus, 4.–5. Jh."
    title_sub: "Heiliger (~360–435), asketischer Schriftsteller, Mönch, Theologe, Begründer des Mönchtums in Gallien, der die Regeln der östlichen Klöster in den Westen übertrug"
    copy_cover: true
    menu: {{ parent: "5. Jahrhundert", title: "Johannes Cassianus, Heiliger (~360–435)", replace: "Johannes Cassianus, Heiliger (~360–435)", priority: 2 }}
    update: true
    body: |-
{block(author_html)}
'''
    works = f'''# Иоанн Кассиан: труды (немецкая библиотека)
# Сборка: script/translations/de/build_cassian.py

lang: de
list: "Johannes_Cassianus"
folders:
  - {{ path: "Asketische Werke", priority: 1 }}
  - {{ path: "Dogmatische Werke", priority: 2 }}
pages:

{page('W2qj_О_постановлениях_монастырских', 'Cassian_Institutionen', 'Von den Einrichtungen der Klöster', 'inst', 'Asketische Werke', 1, sections('inst'))}
{page('xhIX_О_Воплощении_Господа_против_Нестория_Семь_книг', 'Cassian_Menschwerdung', 'Sieben Bücher über die Menschwerdung Christi', 'inc', 'Dogmatische Werke', 1, sections('inc'))}
{page('MmvV_Собеседования_египетских_подвижников_Писания_к_10ти_110_посланным_к_епископу_Леонтию_и_Елладию_собеседованиям_отцов_пребывавших_в_скитской_пустыне_1', 'Cassian_Unterredungen_1', 'Vierundzwanzig Unterredungen mit den Vätern — Teil 1', 'conf', 'Asketische Werke', 2, conf1)}
{page('Uovl_Собеседования_египетских_подвижников_Писания_к_7ми_1117_другим_посланным_к_епископу_Гонорату_и_Евхерию_собеседованиям_отцов_живших_в_египетской_пустыне_Фиваиде', 'Cassian_Unterredungen_2', 'Vierundzwanzig Unterredungen mit den Vätern — Teil 2', 'conf', 'Asketische Werke', 3, conf2)}
'''
    for name, text in (('cassian_author.yml', author), ('cassian_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
