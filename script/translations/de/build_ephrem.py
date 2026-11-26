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


def sections4(key):
    with zipfile.ZipFile(os.path.join(TMP, 'eph4_' + key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for i, heading in enumerate(doc.xpath('//h2'), 1):
        body = [f'<h2>{i}</h2>']
        for sub in heading.getparent().xpath('.//h3'):
            title = ''.join(sub.itertext()).strip()
            text = ''.join(be.para_html(p) for p in sub.getparent().xpath('.//p'))
            body.append(f'<h3>{title}</h3>{text}')
        if len(body) == 1:
            body.append(''.join(be.para_html(p) for p in heading.getparent().xpath('.//p')))
        parts.append(''.join(body))
    return ''.join(parts)


def sections(key):
    with zipfile.ZipFile(os.path.join(TMP, 'eph2_' + key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for i, heading in enumerate(doc.xpath('//h2'), 1):
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        parts.append(f'<h2>{i}</h2>{body}')
    return ''.join(parts)


def hymns():
    with zipfile.ZipFile(os.path.join(TMP, 'eph_hym.epub')) as z:
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
  - {{ path: "Reden", priority: 2 }}
  - {{ path: "Asketische Werke", priority: 3 }}
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

  - src: "EdGB_Творения__Часть_1"
    path: "Ephraem_Hymnen_gegen_die_Irrlehren"
    title: "Hymnen gegen die Irrlehren"
    menu: {{ parent: "Werke", title: "Hymnen gegen die Irrlehren", priority: 2 }}
    update: true
    body: |-
{block('<p><em>Hymnen gegen die Irrlehren (Bibliothek der Kirchenväter).</em></p>' + hymns())}
    references: |-
{block('<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Hymnen gegen die Irrlehren</em>. Text nach <a href="https://bkv.unifr.ch/de/works/cpg-3949/versions/hymnen-gegen-die-irrlehren-bkv">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')}

  - src: "T90c_Творения__Часть_2"
    path: "Ephraem_Drei_Reden_ueber_den_Glauben"
    title: "Drei Reden über den Glauben"
    menu: {{ parent: "Reden", title: "Drei Reden über den Glauben", priority: 1 }}
    update: true
    body: |-
{block('<p><em>Drei Reden über den Glauben (Bibliothek der Kirchenväter).</em></p>' + sections('faith'))}
    references: |-
{block('<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Drei Reden über den Glauben</em>. Text nach <a href="https://bkv.unifr.ch/de/works/cpg-3961/versions/drei-reden-uber-den-glauben-bkv">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')}

  - src: "aClO_Творения__Часть_3"
    path: "Ephraem_Rede_ueber_die_Verklarung"
    title: "Rede über die Verklärung Christi"
    menu: {{ parent: "Reden", title: "Rede über die Verklärung Christi", priority: 2 }}
    update: true
    body: |-
{block('<p><em>Rede über die Verklärung Christi (Bibliothek der Kirchenväter).</em></p>' + sections('trans'))}
    references: |-
{block('<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Rede über die Verklärung Christi</em>. Text nach <a href="https://bkv.unifr.ch/de/works/cpg-3939/versions/rede-uber-die-verklarung-christi-bkv">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')}

  - src: "qbv1_Юлиановский_цикл"
    path: "Ephraem_Vier_Lieder_ueber_Julian"
    title: "Vier Lieder über Julian den Apostaten"
    menu: {{ parent: "Reden", title: "Vier Lieder über Julian den Apostaten", priority: 4 }}
    update: true
    body: |-
{block('<p><em>Vier Lieder über Julian den Apostaten (Bibliothek der Kirchenväter).</em></p>' + sections('jul'))}
    references: |-
{block('<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Vier Lieder über Julian den Apostaten</em>. Text nach <a href="https://bkv.unifr.ch/de/works/cpg-4027/versions/vier-lieder-uber-julian-den-apostaten-bkv">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')}

  - src: "RAEO_Творения__Часть_4"
    path: "Ephraem_Rede_ueber_Jonas"
    title: "Rede über den Propheten Jonas"
    menu: {{ parent: "Reden", title: "Rede über den Propheten Jonas", priority: 3 }}
    update: true
    body: |-
{block('<p><em>Rede über den Propheten Jonas (Bibliothek der Kirchenväter).</em></p>' + sections('jonas'))}
    references: |-
{block('<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Rede über den Propheten Jonas</em>. Text nach <a href="https://bkv.unifr.ch/de/works/cpg-4082/versions/rede-uber-den-propheten-jonas-und-die-busse-der-niniviten-jonas-32-3-bkv">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')}

  - src: "fNhS_Поучительные_слова_к_египетским_монахам"
    path: "Ephraem_Asketische_Abhandlungen"
    title: "Auswahl asketischer Abhandlungen"
    menu: {{ parent: "Asketische Werke", title: "Auswahl asketischer Abhandlungen", priority: 1 }}
    update: true
    body: |-
{block('<p><em>Auswahl asketischer Abhandlungen (Bibliothek der Kirchenväter).</em></p>' + sections4('asc'))}
    references: |-
{block('<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Auswahl asketischer Abhandlungen</em>. Text nach <a href="https://bkv.unifr.ch/de/works/-38b/versions/auswahl-ascetischer-abhandlungen-uber-die-christliche-tugend-und-vollkommenheit-bkv">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')}

  - src: "mfw6_Надгробные_песнопения"
    path: "Ephraem_Nisibische_Hymnen"
    title: "Ausgewählte nisibische Hymnen"
    menu: {{ parent: "Werke", title: "Ausgewählte nisibische Hymnen", priority: 3 }}
    update: true
    body: |-
{block('<p><em>Ausgewählte nisibische Hymnen (Bibliothek der Kirchenväter).</em></p>' + sections4('nis'))}
    references: |-
{block('<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Ausgewählte nisibische Hymnen</em>. Text nach <a href="https://bkv.unifr.ch/de/works/-13b/versions/ausgewahlte-nisibenische-hymnen-bkv">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')}
'''
    for name, text in (('ephrem_author.yml', author), ('ephrem_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
