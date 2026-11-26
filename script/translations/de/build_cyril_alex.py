#!/usr/bin/env python3
"""Сборка немецкого Кирилла Александрийского: автор + «О вочеловечении»."""
import os
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402

DB = os.path.join(ROOT, 'db', 'translations', 'de')
TMP = os.path.join(ROOT, 'tmp', 'de_bkv')
AUTHOR = os.path.join(ROOT, 'script', 'translations', 'de', 'authors', 'cyrill_alexandrien.html')
SOURCE = (
    '<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Über die Menschwerdung des '
    'Eingeborenen</em> (Bibliothek der Kirchenväter). Text nach '
    '<a href="https://bkv.unifr.ch/de/works/-43a/versions/uber-die-menschwerdung-des-eingeborenen-bkv">'
    'bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>'
)


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def paragraphs(key):
    with zipfile.ZipFile(os.path.join(TMP, 'cyral_' + key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    return ''.join(be.para_html(p) for p in doc.xpath('//p'))


def fide_sections():
    with zipfile.ZipFile(os.path.join(TMP, 'cyral_fide.epub')) as z:
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
    with zipfile.ZipFile(os.path.join(TMP, 'cyral_letters.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for i, heading in enumerate(doc.xpath('//h2'), 1):
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        parts.append(f'<h2>{i}</h2>{body}')
    return ''.join(parts)


def body():
    with zipfile.ZipFile(os.path.join(TMP, 'cyral_inc.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    return ''.join(be.para_html(p) for p in doc.xpath('//p'))


def main():
    author_html = open(AUTHOR, encoding='utf-8').read().strip()
    author = f'''# Кирилл Александрийский: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_cyril_alex.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "g1QT_Кирилл_Александрийский_V_век"
    path: "Cyrill_von_Alexandrien"
    title: "Cyrill von Alexandrien, 5. Jh."
    title_sub: "Heiliger (~376–444), Erzbischof von Alexandrien, Kirchenvater und Kirchenlehrer"
    copy_cover: true
    menu: {{ parent: "5. Jahrhundert", title: "Cyrill von Alexandrien, Heiliger (~376–444)", replace: "Cyrill von Alexandrien, Heiliger (~376–444)", priority: 1 }}
    update: true
    body: |-
{block(author_html)}
'''
    works = f'''# Кирилл Александрийский: труд (немецкая библиотека)
# Сборка: script/translations/de/build_cyril_alex.py

lang: de
list: "Cyrill_von_Alexandrien"
folders:
  - {{ path: "Dogmatische Werke", priority: 1 }}
  - {{ path: "Briefe", priority: 2 }}
pages:

  - src: "kKgs_Диалог_о_вочеловечении_Единородного"
    path: "Cyrill_Alexandrien_Menschwerdung"
    title: "Über die Menschwerdung des Eingeborenen"
    menu: {{ parent: "Dogmatische Werke", title: "Über die Menschwerdung des Eingeborenen", priority: 1 }}
    update: true
    body: |-
{block('<p><em>Über die Menschwerdung des Eingeborenen (Bibliothek der Kirchenväter).</em></p>' + body())}
    references: |-
{block(SOURCE)}
'''
    works += f'''  - src: "PJql_Послание_1е_писанное_из_Родоса_прежде_собора"
    path: "Cyrill_Alexandrien_Oekumenische_Briefe"
    title: "Drei ökumenische Briefe"
    menu: {{ parent: "Briefe", title: "Drei ökumenische Briefe", priority: 1 }}
    update: true
    body: |-
{block('<p><em>Drei ökumenische Briefe (Bibliothek der Kirchenväter).</em></p>' + letter_sections())}
    references: |-
{block('<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Drei ökumenische Briefe</em>. Text nach <a href="https://bkv.unifr.ch/de/works/123x/versions/drei-okumenische-briefe-bkv">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')}
'''
    works += f'''  - src: "FQe8_О_правой_вере_царевнам_Часть_I"
    path: "Cyrill_Alexandrien_Rechter_Glaube"
    title: "Über den rechten Glauben an den Kaiser"
    menu: {{ parent: "Dogmatische Werke", title: "Über den rechten Glauben an den Kaiser", priority: 2 }}
    update: true
    body: |-
{block('<p><em>Über den rechten Glauben an den Kaiser (Bibliothek der Kirchenväter).</em></p>' + fide_sections())}
    references: |-
{block('<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Über den rechten Glauben an den Kaiser</em>. Text nach <a href="https://bkv.unifr.ch/de/works/cpg-3218/versions/uber-den-rechten-glauben-an-den-kaiser-bkv">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')}
'''
    works += f'''  - src: "gwGO_На_Святой_Символ"
    path: "Cyrill_Alexandrien_Symbol"
    title: "Erklärung des nicäischen Glaubensbekenntnisses"
    menu: {{ parent: "Dogmatische Werke", title: "Erklärung des nicäischen Glaubensbekenntnisses", priority: 3 }}
    update: true
    body: |-
{block('<p><em>Erklärung des nicäischen Glaubensbekenntnisses (Bibliothek der Kirchenväter).</em></p>' + paragraphs('symb'))}
    references: |-
{block('<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Erklärung des nicäischen Glaubensbekenntnisses</em>. Text nach <a href="https://bkv.unifr.ch/de/works/cpg-5355/versions/erklarung-des-nizanischen-glaubensbekenntnisses-bkv">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')}
'''
    for name, text in (('cyril_alex_author.yml', author), ('cyril_alex_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
