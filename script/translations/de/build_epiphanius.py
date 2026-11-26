#!/usr/bin/env python3
"""Сборка немецкого Епифания Кипрского: автор + «Анкорат»."""
import os
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
DB = os.path.join(ROOT, 'db', 'translations', 'de')
OUT = os.path.join(ROOT, 'tmp', 'de_bkv', 'out')

AUTHOR = (
    '<p><strong>Gedenktag:</strong> 12. (25.) Mai</p>'
    '<h2>Biographie</h2>'
    '<p>Über sein Leben ist äußerst wenig bekannt. Es gilt, dass er seiner Herkunft nach Phönizier war und im Hause eines reichen Juden erzogen wurde. Nach dem Tod seines Lehrers nahm er das Christentum an und zog sich nach Ägypten zurück. Er kehrte nach Palästina zurück, wo er Schüler des Abba Hilarion wurde. Nach langen asketischen Übungen siedelte er nach Zypern über und wurde 367 zum Bischof von Salamis geweiht.</p>'
    '<p>Im Jahr 403 begab er sich auf Anstiftung des Theophilus von Alexandrien nach Konstantinopel, um den heiligen Johannes Chrysostomus des Origenismus anzuklagen; nach einer persönlichen Begegnung überzeugte er sich jedoch von der Falschheit der Anschuldigungen und dem politischen Hintergrund der Pläne des Theophilus. Als er sich nach Zypern begab, starb er während der Seereise unweit der Küste der Insel. Der Überlieferung der Väter zufolge wurde er mit sechzig Jahren Bischof und stand fünfundfünfzig Jahre im bischöflichen Dienst; er starb im Alter von einhundertsechzehn Jahren.</p>'
    '<h2>Hymnographie</h2>'
    '<p><strong>Tropar der heiligen Epiphanius von Zypern und Germanus von Konstantinopel, 4. Ton</strong></p>'
    '<blockquote><p>Gott unserer Väter, / der du allezeit mit uns nach deiner Sanftmut handelst, / nimm deine Barmherzigkeit nicht von uns, / sondern durch ihre Gebete // lenke unser Leben in Frieden.</p></blockquote>'
    '<p><strong>Kondak der heiligen Epiphanius von Zypern und Germanus von Konstantinopel, 4. Ton</strong></p>'
    '<blockquote><p>Das wunderbare Paar der heiligen Hierarchen lasst uns, ihr Gläubigen, gebührend preisen, / mit Germanus den göttlichen Epiphanius: / Denn sie verbrannten die gottlosen Zungen / und legten allen die weisesten Dogmen vor, // die dem orthodoxen Bekenntnis das große Geheimnis der Frömmigkeit singen.</p></blockquote>'
    '<p><strong>Verherrlichung</strong></p>'
    '<blockquote><p>Wir verherrlichen euch, / ihr großen Hierarchen Epiphanius und Germanus, / und ehren euer heiliges Gedächtnis, // denn ihr bittet für uns Christus, unseren Gott.</p></blockquote>'
)

SOURCE = (
    '<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Der Festgeankerte (Ancoratus)</em> '
    '(Bibliothek der Kirchenväter). Text nach '
    '<a href="https://bkv.unifr.ch/de/works/cpg-3744/versions/der-festgeankerte-bkv">bkv.unifr.ch</a>; '
    'die Anmerkungen der Ausgabe sind weggelassen.</p>'
)


sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402


def sections():
    with zipfile.ZipFile(os.path.join(ROOT, 'tmp', 'de_bkv', 'epiph_anc.epub')) as z:
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


def main():
    body = ('<p><em>Der Festgeankerte (Ancoratus) (Bibliothek der Kirchenväter).</em></p>'
            + sections())
    author = f'''# Епифаний Кипрский: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_epiphanius.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "K60r_Епифаний_Кипрский_IV_век"
    path: "Epiphanius_von_Salamis"
    title: "Epiphanius von Salamis, 4. Jh."
    title_sub: "Heiliger (~315–403), berühmter Kirchenvater und Wundertäter, Kämpfer gegen verschiedene Häresien"
    copy_cover: true
    menu: {{ parent: "4. Jahrhundert", title: "Epiphanius von Salamis, Heiliger (~315–403)", replace: "Epiphanius von Salamis, Heiliger (~315–403)", priority: 12 }}
    update: true
    body: |-
{block(AUTHOR)}
'''
    works = f'''# Епифаний Кипрский: труд (немецкая библиотека)
# Сборка: script/translations/de/build_epiphanius.py

lang: de
list: "Epiphanius_von_Salamis"
folders:
  - {{ path: "Dogmatische Werke", priority: 1 }}
pages:

  - src: "qhil_Слово_якорное_Анкорат"
    path: "Epiphanius_Ancoratus"
    title: "Der Festgeankerte (Ancoratus)"
    menu: {{ parent: "Dogmatische Werke", title: "Der Festgeankerte (Ancoratus)", priority: 1 }}
    update: true
    body: |-
{block(body)}
    references: |-
{block(SOURCE)}
'''
    for name, text in (('epiph_author.yml', author), ('epiph_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
