#!/usr/bin/env python3
"""Сборка немецкого Иеронима Стридонского: автор + три труда (BKV)."""
import os
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402

DB = os.path.join(ROOT, 'db', 'translations', 'de')
OUT = os.path.join(ROOT, 'tmp', 'de_bkv', 'out')
TMP = os.path.join(ROOT, 'tmp', 'de_bkv')

AUTHOR = (
    '<p><strong>Gedenktag:</strong> 15. (28.) Juni</p>'
    '<h2>Biographie</h2>'
    '<p>Über die ersten Lebensjahre des seligen Hieronymus von Stridon ist wenig bekannt. Die Zeit hat sowohl das genaue Datum seiner Geburt als auch sogar seinen weltlichen Namen der Vergessenheit anheimfallen lassen (es gibt jedoch Anlass zu der Annahme, dass er Eusebius hieß). Der Geburtsort des Hieronymus ist Stridon (eine kleine Stadt an der Grenze zweier Gebiete: Dalmatien und Pannonien). Die Eltern des Hieronymus waren Christen. Es gibt die Version, dass sie ihrem sozialen Status nach zu den wohlhabenden Freigelassenen gehörten.</p>'
    '<p>Die erste Bildung erhielt Hieronymus unter der Leitung eines Lehrers zu Hause. Dann begab er sich auf Wunsch der Eltern nach Rom, wo er seine Ausbildung fortsetzte. Unter anderen Bildungsdisziplinen studierte er Philosophie und Beredsamkeit. Während seines Aufenthalts in Rom erlebte er viele Versuchungen, die er keineswegs immer überwand. Bei alledem gelang es ihm, jenes Flämmchen des Glaubens zu bewahren, das ihm in der Kindheit Mutter und Vater ins Herz gepflanzt hatten. An den Sonntagen beispielsweise besuchte er gern die Gräber der christlichen Märtyrer, deren Eindruck seine Seele so stark berührte, dass es ihm, nach eigenem Bekenntnis, schien, als stiege er selbst lebendig ins Grab hinab.</p>'
    '<p>Während seines Aufenthalts in Rom beschloss Hieronymus, sein Leben zu ändern. Vermutlich empfing er in dieser Zeit die Taufe. Nachdem er die ewige Stadt verlassen hatte, dachte er während einer Reise durch Gallien ernsthaft über das Mönchtum nach. Als er 372 in sein heimatliches Stridon zurückkehrte, fand er seine Eltern nicht mehr am Leben. Die Notwendigkeit, sich um die Schwester und den jüngeren Bruder sowie um das elterliche Erbe zu kümmern, zwang ihn, seine Pläne eines Einsiedlerlebens aufzuschieben. Eine Zeit lang lebte er in Aquileia im Umgang mit Gefährten eines „halbmönchischen“ Kreises. Dann unternahm er eine Reise in den Osten, mit der Absicht, Jerusalem, Syrien und Ägypten zu besuchen. Als er jedoch Antiochien erreichte, erkrankte er schwer.</p>'
    '<p>Nach der Genesung ließ er sich in der syrischen Thebais nieder, wie man annimmt, in einem dortigen Kloster. Dort lebte er etwa fünf Jahre in asketischen Übungen und Gebet. In dieser Zeit studierte er die Heilige Schrift und die hebräische Sprache. In Antiochien schloss er sich der Gemeinde des Bischofs Paulinus an und wurde zum Priester geweiht. Kurze Zeit später begab er sich nach Konstantinopel, wo er Umgang mit zwei großen Hierarchen hatte: Gregor von Nazianz und Gregor von Nyssa. Im Jahr 381 verließ er Konstantinopel und begab sich nach Rom. Zu dieser Zeit fand dort eine Synode statt, die wegen des meletianischen Schismas einberufen worden war. In Rom wurde der selige Vater mit dem Amt eines Sekretärs bei Papst Damasus betraut.</p>'
    '<p>Nicht alle nahmen das hochgeistliche Leben des Vaters Hieronymus an: für viele war er ein Ankläger. Gegen den Heiligen begannen Intrigen. Verleumdungen ergossen sich. Zu allen übrigen Anschuldigungen kam noch der Vorwurf der Sympathie für Origenes hinzu.</p>'
    '<p>Mit dem Tod Papst Damasus’ im Jahr 384 verstärkte sich der Druck auf den Vater Hieronymus nur noch: Der neue Papst Siricius mochte ihn nicht. Da verließ der Selige, seinen Bruder Paulinianus mitnehmend, Rom und begab sich ins Heilige Land. Nach der Verehrung der heiligen Stätten unternahm er eine Pilgerreise nach Ägypten. Hier hatte er das Glück, Didymus den Blinden zu hören und mit den nitrischen Wüstenvätern zu sprechen.</p>'
    '<p>Im Jahr 386 übernahm Hieronymus die Leitung eines Klosters in Bethlehem. Neben der Leitung des Klosters und asketischen Übungen widmete er sich der literarischen Tätigkeit.</p>'
    '<p>Der Beitrag des seligen Hieronymus zur kirchlichen Schriftstellerei ist kaum zu überschätzen. Nach ihm blieb ein umfangreiches literarisches Erbe zurück. Eine seiner wichtigsten Leistungen gilt als die Übersetzung der Bücher der Heiligen Schrift ins Lateinische. Am 30. September 420 entschlief der Heilige im Herrn.</p>'
    '<h2>Hymnographie</h2>'
    '<p>Tropar des seligen Hieronymus von Stridon</p>'
    '<blockquote><p>Groß hast du, du Gottweiser, / als Fürsprecher vor dir die Versammlung der Rechtgläubigen, / denn du bist ein Genosse der Heiligen / und ein Teilhaber der göttlichen Weisheit; / so bitte, wunderbarer Hieronymus, / Christus Gott, // dass er uns große Barmherzigkeit schenke.</p></blockquote>'
    '<p>Kondak des heiligen Hieronymus von Stridon, 8. Ton</p>'
    '<blockquote><p>Den Heiligsten unter den Heiligen und den Seligsten unter den Seligen, den Lehrer, / lasst uns mit Liedern preisen, den lobenswerten Hieronymus, / den Führer und Fürsprecher der Gläubigen, ihm in Liebe zurufend: / Freue dich, gottweiser Vater.</p></blockquote>'
)

SOURCES = {
    'pel': ('Dialog gegen die Pelagianer', 'https://bkv.unifr.ch/de/works/cpl-615/versions/dialog-gegen-die-pelagianer-bkv'),
    'pauli': ('Leben des heiligen Paulus, des ersten Einsiedlers', 'https://bkv.unifr.ch/de/works/cpl-617/versions/leben-des-hl-paulus-des-ersten-einsiedlers-bkv'),
    'hil': ('Leben des heiligen Einsiedlers Hilarion', 'https://bkv.unifr.ch/de/works/cpl-618/versions/leben-des-hl-einsiedlers-hilarion-bkv'),
    'helv': ('Über die beständige Jungfräulichkeit Mariens gegen Helvidius', 'https://bkv.unifr.ch/de/works/cpl-609/versions/uber-die-bestandige-jungfrauschaft-mariens-gegen-helvidius-bkv'),
    'malch': ('Leben und Gefangenschaft des Mönches Malchus', 'https://bkv.unifr.ch/de/works/cpl-619/versions/leben-und-gefangenschaft-des-monches-malchus-bkv'),
    'letters': ('Ausgewählte Briefe', 'https://bkv.unifr.ch/de/works/cpl-620/versions/briefe-bkv-2'),
}


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def letter_sections():
    with zipfile.ZipFile(os.path.join(TMP, 'hier_letters.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for i, heading in enumerate(doc.xpath('//h2'), 1):
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        parts.append(f'<h2>{i}</h2>{body}')
    return ''.join(parts)


def dialog_sections():
    with zipfile.ZipFile(os.path.join(TMP, 'hier_pel.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for i, heading in enumerate(doc.xpath('//h2'), 1):
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        parts.append(f'<h2>{i}</h2>{body}')
    return ''.join(parts)


def paragraphs2(key):
    with zipfile.ZipFile(os.path.join(TMP, 'hier2_' + key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    return ''.join(be.para_html(p) for p in doc.xpath('//p'))


def paragraphs(key):
    with zipfile.ZipFile(os.path.join(TMP, 'hier_' + key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    return ''.join(be.para_html(p) for p in doc.xpath('//p'))


def source(key):
    title, url = SOURCES[key]
    return (f'<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>{title}</em> '
            f'(Bibliothek der Kirchenväter). Text nach <a href="{url}">bkv.unifr.ch</a>; '
            f'die Anmerkungen der Ausgabe sind weggelassen.</p>')


def page(src, path, title, key, parent, priority, body):
    full = f'<p><em>{title} (Bibliothek der Kirchenväter).</em></p>' + body
    return f'''  - src: "{src}"
    path: "{path}"
    title: "{title}"
    menu: {{ parent: "{parent}", title: "{title}", priority: {priority} }}
    update: true
    body: |-
{block(full)}
    references: |-
{block(source(key))}
'''


def main():
    author = f'''# Иероним Стридонский: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_jerome.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "r6fC_Иероним_Стридонский_IV_век"
    path: "Hieronymus"
    title: "Hieronymus, 4. Jh."
    title_sub: "Seliger (~347–419), berühmter Kirchenvater, Autor bedeutender theologischer und sittlicher Schriften, Schöpfer des kanonischen lateinischen Bibeltextes"
    copy_cover: true
    menu: {{ parent: "4. Jahrhundert", title: "Hieronymus, Seliger (~347–419)", replace: "Hieronymus, Seliger (~347–419)", priority: 10 }}
    update: true
    body: |-
{block(AUTHOR)}
'''
    works = f'''# Иероним Стридонский: труды (немецкая библиотека)
# Сборка: script/translations/de/build_jerome.py

lang: de
list: "Hieronymus"
folders:
  - {{ path: "Dogmatische Werke", priority: 1 }}
  - {{ path: "Hagiographische Werke", priority: 2 }}
  - {{ path: "Briefe", priority: 3 }}
pages:

{page('2PqO_Разговор_против_пелагиан', 'Hieronymus_Dialog_gegen_die_Pelagianer', 'Dialog gegen die Pelagianer', 'pel', 'Dogmatische Werke', 1, dialog_sections())}
{page('g76K_Жизнь_Павла_Пустынника', 'Hieronymus_Vita_Pauli', 'Leben des heiligen Paulus, des ersten Einsiedlers', 'pauli', 'Hagiographische Werke', 1, paragraphs('pauli'))}
{page('9ofy_Жизнь_святого_Илариона', 'Hieronymus_Vita_Hilarion', 'Leben des heiligen Einsiedlers Hilarion', 'hil', 'Hagiographische Werke', 2, paragraphs('hil'))}
{page('sWy9_О_Приснодевстве_блаженной_Марии', 'Hieronymus_Gegen_Helvidius', 'Über die beständige Jungfräulichkeit Mariens gegen Helvidius', 'helv', 'Dogmatische Werke', 2, paragraphs2('helv'))}
{page('K3RD_Жизнь_пленного_монаха_Малха', 'Hieronymus_Vita_Malchi', 'Leben und Gefangenschaft des Mönches Malchus', 'malch', 'Hagiographische Werke', 3, paragraphs2('malch'))}
{page('uA9f_Письма_143_1', 'Hieronymus_Ausgewaehlte_Briefe', 'Ausgewählte Briefe (Auswahl)', 'letters', 'Briefe', 1, letter_sections())}
'''
    for name, text in (('hier_author.yml', author), ('hier_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
