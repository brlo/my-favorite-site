#!/usr/bin/env python3
"""Сборка немецкого Илария Пиктавийского: автор + «Против ариан» (1833)."""
import os
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
DB = os.path.join(ROOT, 'db', 'translations', 'de')
OUT = os.path.join(ROOT, 'tmp', 'de_bkv', 'out')

AUTHOR = (
    '<p><strong>Gedenktag:</strong> 13. Januar (Gallien, Griechenland, Rumänien, OCA)</p>'
    '<h2>Biographie</h2>'
    '<p>Nach dem Zeugnis des heiligen Hieronymus wurde er im zweiten Jahrzehnt des 4. Jahrhunderts in Poitiers (Aquitanien) geboren. Aus vornehmem Geschlecht stammend, erhielt er eine klassische Bildung und widmete die frühen Lebensjahre dem Studium der Philosophie. Das Streben, den Sinn des Lebens zu erfassen, führte ihn zum Neuen Testament. Der Überlieferung nach kam, als er den Prolog des Johannesevangeliums las, in dem die Lehre vom göttlichen Wort-Logos dargelegt wird, himmlisches Licht auf ihn herab, was ihn zur Taufe bewog.</p>'
    '<p>Um 350 wurde Hilarius zum Bischof seiner Heimatstadt gewählt, obwohl er zu diesem Zeitpunkt bereits verheiratet war und eine Tochter namens Abra hatte. Hilarius nahm nicht an den Synoden von Arles (353) und Mailand (355) teil, die die Absetzung des heiligen Athanasius von Alexandrien bestätigten, begann jedoch aktiv, die Opposition der gallischen Bischöfe gegen Saturninus, den arianischen Bischof von Arles, zu organisieren, weshalb er von Constantius als politischer Unruhestifter nach Kleinasien verbannt wurde.</p>'
    '<p>Während der Verbannung (356–359) verfasste Hilarius sein wichtigstes theologisches Werk, die Abhandlung „Über die Dreieinigkeit“ (De Trinitate), die dem Beweis der Gottheit des Sohnes gewidmet ist. Interessant ist, dass Hilarius in einem anderen wichtigen Werk, „Über die Synoden“ (De synodis), erzählt, dass er erst unmittelbar vor der Verbannung das nicäische Glaubensbekenntnis kennenlernte. In der Abhandlung „Über die Dreieinigkeit“ wird der Gedanke geäußert, dass der Unterschied zwischen rechtgläubiger und häretischer Lehre manchmal ein unterschiedliches Verständnis der Begriffe sein könne und nicht wirkliche Glaubensverschiedenheit.</p>'
    '<p>Von der Liberalität seiner Anschauungen zeugt der Erfolg, den Hilarius bei der Herstellung von Kontakten mit verschiedenen religiösen Parteien im Osten erzielte. Zugleich verurteilte Hilarius als „Sakrileg“ die Erklärung der extremen Arianer, die die sogenannte zweite Sirmische Formel (357) annahmen, wonach der Sohn dem Vater „nicht ähnlich“ sei. Auf der Synode von Seleucia (359) begrüßte er den Sieg der gemäßigten Partei unter Führung des Bischofs Basilius von Ancyra und billigte die Annahme des antiochenischen Glaubensbekenntnisses, das zur Garantie der Rechtgläubigkeit der Ostkirche werden konnte.</p>'
    '<p>Anfang 360 wandte sich Hilarius an den Kaiser mit der Bitte, ihm eine öffentliche Disputation mit Saturninus von Arles zu gestatten und an einer neuen Synode in Konstantinopel teilzunehmen („An Constantius Augustus“, zweites Buch), erhielt jedoch auf beide Bitten eine Absage, woraufhin er mit einer offenen Anklage des Constantius hervortrat („Gegen Constantius Augustus“). Dennoch wurde Hilarius 361 die Rückkehr nach Gallien erlaubt, wo er seinen Kampf gegen Saturninus wieder aufnahm, infolgedessen dieser auf der Synode von Paris (361) erneut verurteilt wurde.</p>'
    '<p>Von diesem Zeitpunkt an verlor das Arianismus seine Positionen in Gallien, und Hilarius versuchte, den Kaiser Julian zu überzeugen, den Arianer Auxentius, Bischof von Mailand, in die Verbannung zu schicken; doch der den Arianern gegenüber tolerante heidnische Kaiser weigerte sich. Hilarius starb wahrscheinlich am 13. Januar 367.</p>'
    '<p>Hilarius von Poitiers wird in den Akten des Fünften Ökumenischen Konzils unter den heiligen Vätern und Lehrern der Kirche genannt, deren orthodoxe Lehre von der Kirche als Maßstab angenommen wird.</p>'
)

SOURCE = (
    '<p><strong>Quelle:</strong> Übersetzung aus dem 19. Jahrhundert, <em>Gegen die Arianer, oder gegen '
    'Auxentius von Mailand</em> (Sämmtliche Werke der Kirchen-Väter 9), Kempten 1833. Text nach '
    '<a href="https://bkv.unifr.ch/de/works/cpl-462/versions/gegen-die-arianer-oder-gegen-auxentius-von-mailand-bkv">'
    'bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>'
)


sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402


def ps_sections():
    with zipfile.ZipFile(os.path.join(ROOT, 'tmp', 'de_bkv', 'hil_ps.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for i, heading in enumerate(doc.xpath('//h2'), 1):
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        parts.append(f'<h2>{i}</h2>{body}')
    return ''.join(parts)


def trin_sections():
    with zipfile.ZipFile(os.path.join(ROOT, 'tmp', 'de_bkv', 'hil_trin.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for i, heading in enumerate(doc.xpath('//h2'), 1):
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        parts.append(f'<h2>{i}</h2>{body}')
    return ''.join(parts)


def arian_sections():
    with zipfile.ZipFile(os.path.join(ROOT, 'tmp', 'de_bkv', 'hil_arian.epub')) as z:
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
    body = ('<p><em>Gegen die Arianer, oder gegen Auxentius von Mailand (Kempten 1833).</em></p>'
            + arian_sections())
    author = f'''# Иларий Пиктавийский: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_hilary.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "97nZ_Иларий_Пиктавийский_святитель_315367"
    path: "Hilarius_von_Poitiers"
    title: "Hilarius von Poitiers, 4. Jh."
    title_sub: "Heiliger (~315–367), Bischof von Poitiers, Kirchenvater und Kirchenlehrer, Verteidiger des nicäischen Glaubens"
    copy_cover: true
    menu: {{ parent: "4. Jahrhundert", title: "Hilarius von Poitiers, Heiliger (~315–367)", replace: "Hilarius von Poitiers, Heiliger (~315–367)", priority: 8 }}
    update: true
    body: |-
{block(AUTHOR)}
'''
    works = f'''# Иларий Пиктавийский: труд (немецкая библиотека)
# Сборка: script/translations/de/build_hilary.py

lang: de
list: "Hilarius_von_Poitiers"
folders:
  - {{ path: "Dogmatische Werke", priority: 1 }}
  - {{ path: "Exegetische Werke", priority: 2 }}
pages:

  - src: "VtDG_Против_ариан_или_Против_Авксентия"
    path: "Hilarius_Gegen_die_Arianer"
    title: "Gegen die Arianer, oder gegen Auxentius von Mailand"
    menu: {{ parent: "Dogmatische Werke", title: "Gegen die Arianer, oder gegen Auxentius von Mailand", priority: 1 }}
    update: true
    body: |-
{block(body)}
    references: |-
{block(SOURCE)}
'''
    works += f'''  - src: "r6LM_О_Троице_фрагменты"
    path: "Hilarius_De_Trinitate"
    title: "Zwölf Bücher über die Dreieinigkeit"
    menu: {{ parent: "Dogmatische Werke", title: "Zwölf Bücher über die Dreieinigkeit", priority: 2 }}
    update: true
    body: |-
{block('<p><em>Zwölf Bücher über die Dreieinigkeit (Bibliothek der Kirchenväter).</em></p>' + trin_sections())}
    references: |-
{block('<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Zwölf Bücher über die Dreieinigkeit</em>. Text nach <a href="https://bkv.unifr.ch/de/works/cpl-433/versions/zwolf-bucher-uber-die-dreieinigkeit-bkv">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')}

  - src: "EAJa_Беседа_на_псалом_130"
    path: "Hilarius_Psalmen"
    title: "Abhandlungen über die Psalmen"
    menu: {{ parent: "Exegetische Werke", title: "Abhandlungen über die Psalmen", priority: 1 }}
    update: true
    body: |-
{block('<p><em>Abhandlungen über die Psalmen (Bibliothek der Kirchenväter).</em></p>' + ps_sections())}
    references: |-
{block('<p><strong>Quelle:</strong> Übersetzung der BKV-Ausgabe, <em>Abhandlungen über die Psalmen</em>. Text nach <a href="https://bkv.unifr.ch/de/works/cpl-428/versions/abhandlungen-uber-die-psalmen-bkv">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')}
'''
    for name, text in (('hil_author.yml', author), ('hil_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
