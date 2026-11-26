#!/usr/bin/env python3
"""Сборка немецкого Амвросия Медиоланского: автор + три труда (BKV)."""
import os
import re
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402

DB = os.path.join(ROOT, 'db', 'translations', 'de')
TMP = os.path.join(ROOT, 'tmp', 'de_bkv')

AUTHOR = (
    '<h2>Biographie</h2>'
    '<p>Gedenktag: 7. (20.) Dezember</p>'
    '<p>Der heilige Ambrosius von Mailand wurde in Augusta Treverorum (Treveris; heute Trier) geboren. Als sein Geburtsjahr gilt traditionell 339. Seine Eltern stammten aus Rom und gehörten zu aristokratischen Familien mit alten christlichen Traditionen. Zu seinen Verwandten zählten neben Konsuln die heilige Jungfrau Soteria, die während der Verfolgung unter Kaiser Diokletian das Martyrium erlitt. Nach dem Tod ihres Mannes im Jahr 340 zog Ambrosius’ Mutter mit den kleinen Kindern nach Rom.</p>'
    '<p>Ambrosius erhielt eine glänzende Ausbildung. Seine erste Stellung im Staatsdienst war die eines Advokaten in Sirmium (Präfektur Illyrien); einige Zeit später ernannte ihn der Prätorianerpräfekt Petronius Probus zum Berater. Um 370 erhielt Ambrosius auf Fürsprache des Probus das Amt eines Konsulars (Statthalters, Gouverneurs) der Provinz Aemilia-Liguria mit Zentrum in Mediolanum (heute Mailand).</p>'
    '<p>Im Jahr 374 wurde Ambrosius nach dem Tod des mailändischen Bischofs Auxentius I. von der örtlichen christlichen Gemeinde auf den mailändischen Bischofsstuhl gewählt, obwohl er zu dieser Zeit noch nicht einmal getauft war. Anfangs widerstrebte der heilige Ambrosius der Wahl, willigte dann aber ein, den Bischofsstuhl zu übernehmen. Kurze Zeit nach der Taufe wurde er zum Bischof erhoben. Danach verteilte er sein Vermögen und führte bis zu seinem Lebensende einen strengen Lebenswandel.</p>'
    '<p>Da der heilige Ambrosius in theologischen Fragen nicht besonders bewandert war, begann er, die Heilige Schrift eifrig anhand der Auslegungen bekannter christlicher Schriftsteller zu studieren, und eignete sich bald einen gewichtigen Schatz an Kenntnissen auf diesem Gebiet an. Als überzeugter Anhänger des nicäischen Orthodoxie trat er dem Arianismus entgegen und überzeugte recht schnell viele schwankende und irrende Gläubige aus seiner Herde. Er bekämpfte auch deren alte heidnische Gewohnheiten. Als Kaiser Theodosius der Große bei der Niederschlagung des Aufstands in Thessaloniki übermäßige Härte zeigte, soll Ambrosius ihm verboten haben, sich den Sakramenten der Kirche zu nähern. Der Kaiser unterwarf sich in seiner ihm eigenen Achtung vor der kirchlichen Disziplin und tat öffentlich Buße.</p>'
    '<p>Ambrosius gewann die große Liebe seiner Herde. Die Überlieferung berichtet von Wundern, die auf seine Gebete hin geschahen. In den letzten Lebensjahren widmete er sich mehr der literarischen Tätigkeit und diktierte seine Schriften seinem Sekretär Paulinus. Am 4. April 397 entschlief der Heilige friedlich im Herrn. Die Verehrung des Ambrosius entstand sowohl im Westen als auch im Osten sogleich nach seinem Tod, wovon die bereits im 5. Jahrhundert entstandenen lateinischen und griechischen Lebensbeschreibungen zeugen.</p>'
    '<p>Ambrosius von Mailand ist für sein reiches literarisch-theologisches Erbe bekannt. Unter seinen Werken finden sich Schriften exegetischen, dogmatischen, moralisch-sittlichen, hymnographischen und anderen Charakters.</p>'
    '<h2>Hymnographie</h2>'
    '<h3>Tropar des heiligen Ambrosius von Mailand (4. Ton):</h3>'
    '<blockquote><p>Als Regel des Glaubens und Bild der Sanftmut, / als Lehrer der Enthaltsamkeit / erwies dich deiner Herde / die Wahrheit der Dinge. / Darum erlangtest du durch Demut das Hohe, / durch Armut das Reiche, / Vater Ambrosius, / bitte Christus Gott, // dass unsere Seelen gerettet werden.</p></blockquote>'
    '<h3>Kondak des heiligen Ambrosius von Mailand (3. Ton):</h3>'
    '<blockquote><p>Mit göttlichen Dogmen erstrahlend, / verdunkeltest du den Betrug des Arius, / du geheimnisvoller Priester und Hirte Ambrosius, / und durch die Kraft des Geistes Wunder wirkend, / hast du offenkundig verschiedene Leiden geheilt, / ehrwürdiger Vater, // bitte Christus Gott, dass unsere Seelen gerettet werden.</p></blockquote>'
    '<h3>Weiterer Kondak des heiligen Ambrosius von Mailand (8. Ton):</h3>'
    '<blockquote><p>Das vortreffliche Wort des Lebens hast du erlangt, weiser Vater, / und dich nicht gescheut vor der königlichen Höhe, / du von Gott belehrter Ankläger des Königs, und hast ihn weise gemacht. / Darum wurdest du umso ehrenvoller geehrt / und hast die Herde deines Volkes zu Gott geführt. / Darum rufen wir dir zu: // Freue dich, wunderbarer Ambrosius.</p></blockquote>'
)

SOURCES = {
    'myst': ('Über die Mysterien', 'https://bkv.unifr.ch/de/works/cpl-155/versions/uber-die-mysterien-bkv', 'BKV-Ausgabe'),
    'exam': ('Exameron', 'https://bkv.unifr.ch/de/works/cpl-123/versions/exameron-bkv', 'Joh. Ev. Niederhuber'),
    'paen': ('Über die Buße', 'https://bkv.unifr.ch/de/works/cpl-156/versions/uber-die-busse-bkv-2', 'Franz Xaver Schulte'),
}


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def paragraphs(key):
    with zipfile.ZipFile(os.path.join(TMP, 'amb_' + key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    return ''.join(be.para_html(p) for p in doc.xpath('//p'))


def exameron_sections():
    with zipfile.ZipFile(os.path.join(TMP, 'amb_exam.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for i, heading in enumerate(doc.xpath('//h2'), 1):
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        parts.append(f'<h2>{i}</h2>{body}')
    return ''.join(parts)


def paenitentia():
    with zipfile.ZipFile(os.path.join(TMP, 'amb_paen.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for book in doc.xpath('//h2'):
        parts.append(f'<h2>Buch {book.text_content().strip().split()[-1]}</h2>')
        for chapter in book.getparent().xpath('./section'):
            h = chapter.find('h3')
            n = be.chapter_number(h) if h is not None else None
            body = ''.join(be.para_html(p) for p in chapter.xpath('.//p'))
            if body:
                parts.append(f'<h2>{n if n is not None else 0}</h2>{body}')
    return ''.join(parts)


def source(key):
    title, url, translator = SOURCES[key]
    return (f'<p><strong>Quelle:</strong> Übersetzung von {translator}, '
            f'<em>{title}</em> (Bibliothek der Kirchenväter). Text nach '
            f'<a href="{url}">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')


def page(src, path, title, key, parent, priority, body=None):
    if body is None:
        body = paragraphs(key)
    full = (f'<p><em>{title}, übersetzt von {SOURCES[key][2]} '
            f'(Bibliothek der Kirchenväter).</em></p>' + body)
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
    author = f'''# Амвросий Медиоланский: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_ambrose.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "Амвросий_Медиоланский"
    path: "Ambrosius_von_Mailand"
    title: "Ambrosius von Mailand, 4. Jh."
    title_sub: "Heiliger (~339–397), Bischof von Mailand, einer der großen westlichen Kirchenväter, Theologe, Hymnendichter, Prediger"
    copy_cover: true
    menu: {{ parent: "4. Jahrhundert", title: "Ambrosius von Mailand, Heiliger (~339–397)", replace: "Ambrosius von Mailand, Heiliger (~339–397)", priority: 7 }}
    update: true
    body: |-
{block(AUTHOR)}
'''
    works = f'''# Амвросий Медиоланский: труды (немецкая библиотека)
# Сборка: script/translations/de/build_ambrose.py

lang: de
list: "Ambrosius_von_Mailand"
folders:
  - {{ path: "Exegetische Werke", priority: 1 }}
  - {{ path: "Dogmatische Werke", priority: 2 }}
  - {{ path: "Moralisch-asketische Werke", priority: 3 }}
pages:

{page('Амвросий_Медиоланский-О_тайнах', 'Ambrosius_De_mysteriis', 'Über die Mysterien', 'myst', 'Dogmatische Werke', 1)}
{page('nCFH_Шестоднев', 'Ambrosius_Exameron', 'Exameron', 'exam', 'Exegetische Werke', 1, exameron_sections())}
{page('hRFw_О_покаянии_две_книги', 'Ambrosius_De_paenitentia', 'Über die Buße', 'paen', 'Moralisch-asketische Werke', 1, paenitentia())}
'''
    for name, text in (('amb_author.yml', author), ('amb_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
