#!/usr/bin/env python3
"""Сборка немецкого Ефрема Сирина: автор + «Слово о Лазаре»."""
import os
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402

DB = os.path.join(ROOT, 'db', 'translations', 'de')
TMP = os.path.join(ROOT, 'tmp', 'de_bkv')
AUTHOR = os.path.join(ROOT, 'script', 'translations', 'de', 'authors', 'ephrem.html')
SOURCE = (
    '<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Rede über die Auferweckung '
    'des Lazarus</em> (Bibliothek der Kirchenväter). Text nach '
    '<a href="https://bkv.unifr.ch/de/works/-18c/versions/rede-uber-die-auferweckung-des-lazarus-joh-11-43-bkv">'
    'bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>'
)


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def body():
    with zipfile.ZipFile(os.path.join(TMP, 'eph_laz.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    return ''.join(be.para_html(p) for p in doc.xpath('//p'))


def main():
    author_html = open(AUTHOR, encoding='utf-8').read().strip()
    author = f'''# Ефрем Сирин: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_ephrem.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "LAUq_Ефрем_Сирин_преподобный_306373"
    path: "Ephraem_der_Syrer"
    title: "Ephräm der Syrer, 4. Jh."
    title_sub: "Heiliger (~306–373), Diakon, Kirchenlehrer, bedeutender syrischer Theologe, Dichter und Prediger"
    copy_cover: true
    menu: {{ parent: "4. Jahrhundert", title: "Ephräm der Syrer, Heiliger (~306–373)", replace: "Ephräm der Syrer, Heiliger (~306–373)", priority: 11 }}
    update: true
    body: |-
{block(author_html)}
'''
    works = f'''# Ефрем Сирин: труд (немецкая библиотека)
# Сборка: script/translations/de/build_ephrem.py

lang: de
list: "Ephraem_der_Syrer"
folders:
  - {{ path: "Predigten", priority: 1 }}
pages:

  - src: "OmGT_Толкования_Священного_ПисанияНа_словаИ_сия_рек_гласом_великим_воззва_Лазаре_гряди_вонИн1143"
    path: "Ephraem_Lazarus"
    title: "Rede über die Auferweckung des Lazarus"
    menu: {{ parent: "Predigten", title: "Rede über die Auferweckung des Lazarus", priority: 1 }}
    update: true
    body: |-
{block('<p><em>Rede über die Auferweckung des Lazarus (Bibliothek der Kirchenväter).</em></p>' + body())}
    references: |-
{block(SOURCE)}
'''
    for name, text in (('ephrem_author.yml', author), ('ephrem_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
