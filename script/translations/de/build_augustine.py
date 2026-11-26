#!/usr/bin/env python3
"""Сборка немецкого Августина: автор + «Энхиридион» (BKV)."""
import os
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402

DB = os.path.join(ROOT, 'db', 'translations', 'de')
TMP = os.path.join(ROOT, 'tmp', 'de_bkv')
AUTHOR = os.path.join(ROOT, 'script', 'translations', 'de', 'authors', 'augustinus.html')
SOURCE = (
    '<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Enchiridion oder Buch vom '
    'Glauben, von der Hoffnung und von der Liebe</em> (Bibliothek der Kirchenväter). Text nach '
    '<a href="https://bkv.unifr.ch/de/works/cpl-295/versions/enchiridion-oder-buch-vom-glauben-von-der-hoffnung-und-von-der-liebe-bkv">'
    'bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>'
)


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def sections(key):
    with zipfile.ZipFile(os.path.join(TMP, 'aug2_' + key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for i, heading in enumerate(doc.xpath('//h2'), 1):
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        parts.append(f'<h2>{i}</h2>{body}')
    return ''.join(parts)


def letter_sections():
    with zipfile.ZipFile(os.path.join(TMP, 'aug_letters.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for i, heading in enumerate(doc.xpath('//h2'), 1):
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        parts.append(f'<h2>{i}</h2>{body}')
    return ''.join(parts)


def conf_parts():
    with zipfile.ZipFile(os.path.join(TMP, 'aug_conf.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    books = []
    for book in doc.xpath('//h2'):
        title = ''.join(book.itertext()).strip()
        parts = [f'<h2>{title}</h2>']
        for chapter in book.getparent().xpath('.//h3'):
            ch_title = ''.join(chapter.itertext()).strip()
            body = ''.join(be.para_html(p) for p in chapter.getparent().xpath('.//p'))
            parts.append(f'<h3>{ch_title}</h3>{body}')
        books.append(''.join(parts))
    return ''.join(books[:7]), ''.join(books[7:])


def trin_sections():
    with zipfile.ZipFile(os.path.join(TMP, 'aug_trin.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for i, heading in enumerate(doc.xpath('//h2'), 1):
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        parts.append(f'<h2>{i}</h2>{body}')
    return ''.join(parts)


def sections3():
    with zipfile.ZipFile(os.path.join(TMP, 'aug3_symb.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for i, heading in enumerate(doc.xpath('//h2'), 1):
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        parts.append(f'<h2>{i}</h2>{body}')
    return ''.join(parts)


def plain(key):
    with zipfile.ZipFile(os.path.join(TMP, 'aug2_' + key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    return ''.join(be.para_html(p) for p in doc.xpath('//p'))


def body():
    with zipfile.ZipFile(os.path.join(TMP, 'aug_ench.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    return ''.join(be.para_html(p) for p in doc.xpath('//p'))


def main():
    conf1, conf2 = conf_parts()
    author_html = open(AUTHOR, encoding='utf-8').read().strip()
    author = f'''# Августин: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_augustine.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "Аврелий_Августин"
    path: "Augustinus_von_Hippo"
    title: "Augustinus von Hippo, 5. Jh."
    title_sub: "Heiliger (354–430), Bischof von Hippo, Kirchenvater und Kirchenlehrer, einer der einflussreichsten Theologen des Westens"
    copy_cover: true
    menu: {{ parent: "5. Jahrhundert", title: "Augustinus von Hippo, Heiliger (354–430)", replace: "Augustinus von Hippo, Heiliger (354–430)", priority: 3 }}
    update: true
    body: |-
{block(author_html)}
'''
    works = f'''# Августин: труд (немецкая библиотека)
# Сборка: script/translations/de/build_augustine.py

lang: de
list: "Augustinus_von_Hippo"
folders:
  - {{ path: "Dogmatische Werke", priority: 1 }}
  - {{ path: "Exegetische Werke", priority: 2 }}
  - {{ path: "Pastorale Werke", priority: 3 }}
  - {{ path: "Autobiographische Werke", priority: 4 }}
  - {{ path: "Briefe", priority: 5 }}
pages:

  - src: "h7gm_Энхиридион_Лаврентию_о_вере_надежде_и_любви"
    path: "Augustinus_Enchiridion"
    title: "Enchiridion oder Buch vom Glauben, von der Hoffnung und von der Liebe"
    menu: {{ parent: "Dogmatische Werke", title: "Enchiridion", priority: 1 }}
    update: true
    body: |-
{block('<p><em>Enchiridion (Bibliothek der Kirchenväter).</em></p>' + body())}
    references: |-
{block(SOURCE)}
'''
    works += f'''  - src: "29CP_Христианская_наука_или_Основания_Герменевтики_и_Церковного_красноречия"
    path: "Augustinus_Christliche_Lehre"
    title: "Vier Bücher über die christliche Lehre"
    menu: {{ parent: "Exegetische Werke", title: "Vier Bücher über die christliche Lehre", priority: 1 }}
    update: true
    body: |-
{block('<p><em>Vier Bücher über die christliche Lehre (Bibliothek der Kirchenväter).</em></p>' + sections('doct'))}
    references: |-
{block('<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Vier Bücher über die christliche Lehre</em>. Text nach <a href="https://bkv.unifr.ch/de/works/cpl-263/versions/vier-bucher-uber-die-christliche-lehre-bkv">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')}
'''
    works += f'''  - src: "2IVd_Об_обучении_оглашаемых"
    path: "Augustinus_Katechetischer_Unterricht"
    title: "Vom ersten katechetischen Unterricht"
    menu: {{ parent: "Pastorale Werke", title: "Vom ersten katechetischen Unterricht", priority: 1 }}
    update: true
    body: |-
{block('<p><em>Vom ersten katechetischen Unterricht (Bibliothek der Kirchenväter).</em></p>' + plain('cate'))}
    references: |-
{block('<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Vom ersten katechetischen Unterricht</em>. Text nach <a href="https://bkv.unifr.ch/de/works/cpl-297/versions/vom-ersten-katechetischen-unterricht-bkv">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')}
'''
    works += f'''  - src: "bEYA_О_Символе_Веры"
    path: "Augustinus_Symbolum"
    title: "Vier Bücher über das Symbolum an die Katechumenen"
    menu: {{ parent: "Dogmatische Werke", title: "Vier Bücher über das Symbolum an die Katechumenen", priority: 2 }}
    update: true
    body: |-
{block('<p><em>Vier Bücher über das Symbolum an die Katechumenen (Bibliothek der Kirchenväter).</em></p>' + sections3())}
    references: |-
{block('<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Vier Bücher über das Symbolum an die Katechumenen</em> (Buch 2–4 von Quodvultdeus). Text nach <a href="https://bkv.unifr.ch/de/works/cpl-309/versions/vier-bucher-uber-das-symbolum-an-die-katechumenen-bkv-buch-2-4-ist-von-quodvultdeus">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')}
'''
    works += f'''  - src: "wAsK_О_Троице"
    path: "Augustinus_De_Trinitate"
    title: "Fünfzehn Bücher über die Dreieinigkeit"
    menu: {{ parent: "Dogmatische Werke", title: "Fünfzehn Bücher über die Dreieinigkeit", priority: 3 }}
    update: true
    body: |-
{block('<p><em>Fünfzehn Bücher über die Dreieinigkeit (Bibliothek der Kirchenväter).</em></p>' + trin_sections())}
    references: |-
{block('<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Fünfzehn Bücher über die Dreieinigkeit</em>. Text nach <a href="https://bkv.unifr.ch/de/works/cpl-329/versions/funfzehn-bucher-uber-die-dreieinigkeit">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')}
'''
    for idx, (src, path, title, part_body, prio) in enumerate([
        ('VbeR_Исповедь_1', 'Augustinus_Bekenntnisse_1', 'Bekenntnisse — Teil 1', conf1, 1),
        ('clsW_Исповедь_2', 'Augustinus_Bekenntnisse_2', 'Bekenntnisse — Teil 2', conf2, 2),
    ], 1):
        works += f'''  - src: "{src}"
    path: "{path}"
    title: "{title}"
    menu: {{ parent: "Autobiographische Werke", title: "{title}", priority: {prio} }}
    update: true
    body: |-
{block('<p><em>Bekenntnisse (Bibliothek der Kirchenväter).</em></p>' + part_body)}
    references: |-
{block('<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Bekenntnisse</em>. Text nach <a href="https://bkv.unifr.ch/de/works/cpl-251/versions/aug-conf-bkv">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')}
'''
    works += f'''  - src: "SnNT_Письма_28_29_246_210"
    path: "Augustinus_Ausgewaehlte_Briefe"
    title: "Ausgewählte Briefe (Auswahl)"
    menu: {{ parent: "Briefe", title: "Ausgewählte Briefe (Auswahl)", priority: 1 }}
    update: true
    body: |-
{block('<p><em>Ausgewählte Briefe (Bibliothek der Kirchenväter).</em></p>' + letter_sections())}
    references: |-
{block('<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Ausgewählte Briefe</em> (erster Teil). Text nach <a href="https://bkv.unifr.ch/de/works/cpl-262/versions/ausgewahlte-briefe-erster-teil-bkv">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')}
'''
    for name, text in (('augustine_author.yml', author), ('augustine_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
