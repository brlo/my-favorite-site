#!/usr/bin/env python3
"""Сборка немецкого Иоанна Златоуста: автор + два труда (BKV)."""
import os
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
DB = os.path.join(ROOT, 'db', 'translations', 'de')
OUT = os.path.join(ROOT, 'tmp', 'de_bkv', 'out')
AUTHOR = os.path.join(ROOT, 'script', 'translations', 'de', 'authors', 'chrysostomus.html')

SOURCES = {
    'sac': ('Über das Priestertum', 'https://bkv.unifr.ch/de/works/cpg-4316/versions/uber-das-priestertum-bkv',
            'Joh. Chrysostomus Baur', 'BKV 1. Reihe, Bd. 27, Kempten/München 1916'),
    'virg': ('Vom jungfräulichen Stande', 'https://bkv.unifr.ch/de/works/cpg-4313/versions/vom-jungfraulichen-stande-bkv',
             'Chrysostomus Mitterrutzner', 'BKV 1. Serie, Bd. 3, Kempten 1890'),
    'theo': ('Erster Brief an Theodor', 'https://bkv.unifr.ch/de/works/cpg-4305/versions/erster-brief-an-theodor-bkv',
             'BKV-Ausgabe', 'BKV'),
    'paen': ('Homilien über die Buße', 'https://bkv.unifr.ch/de/works/cpg-4333/versions/homilien-uber-die-busse-bkv',
             'BKV-Ausgabe', 'BKV'),
    'bild': ('Homilien über die Bildsäulen', 'https://bkv.unifr.ch/de/works/cpg-4330/versions/homilien-uber-die-bildsaulen-bkv',
             'BKV-Ausgabe', 'BKV'),
    'matt': ('Homilien über das Matthäusevangelium', 'https://bkv.unifr.ch/de/works/cpg-4424/versions/kommentar-zum-evangelium-des-hl-matthaus-bkv',
             'BKV-Ausgabe', 'BKV'),
    'rom': ('Homilien über den Römerbrief', 'https://bkv.unifr.ch/de/works/cpg-4427/versions/kommentar-zum-briefe-des-hl-paulus-an-die-romer-bkv',
             'BKV-Ausgabe', 'BKV'),
    'cor1': ('Homilien über den 1. Korintherbrief', 'https://bkv.unifr.ch/de/works/cpg-4428/versions/homilien-uber-den-ersten-brief-an-die-korinther-bkv',
             'BKV-Ausgabe', 'BKV'),
    'cor2': ('Homilien über den 2. Korintherbrief', 'https://bkv.unifr.ch/de/works/cpg-4429/versions/homilien-uber-den-zweiten-brief-an-die-korinther-bkv',
             'BKV-Ausgabe', 'BKV'),
    'gal': ('Kommentar zum Galaterbrief', 'https://bkv.unifr.ch/de/works/cpg-4430/versions/kommentar-zu-den-briefen-des-hl-paulus-an-die-galater-bkv',
            'BKV-Ausgabe', 'BKV'),
    'eph': ('Homilien über den Epheserbrief', 'https://bkv.unifr.ch/de/works/cpg-4431/versions/kommentar-zu-den-briefen-des-hl-paulus-an-die-epheser-bkv',
            'BKV-Ausgabe', 'BKV'),
    'phil': ('Homilien über den Philipperbrief', 'https://bkv.unifr.ch/de/works/cpg-4432/versions/kommentar-zum-briefe-des-hl-paulus-an-die-philipper-bkv',
             'BKV-Ausgabe', 'BKV'),
    'col': ('Homilien über den Kolosserbrief', 'https://bkv.unifr.ch/de/works/cpg-4433/versions/kommentar-zum-briefe-des-hl-paulus-an-die-kolosser-bkv',
            'BKV-Ausgabe', 'BKV'),
    'thes1': ('Homilien über den 1. Thessalonicherbrief', 'https://bkv.unifr.ch/de/works/cpg-4434/versions/homilien-uber-den-i-thessalonicher-brief-bkv',
              'BKV-Ausgabe', 'BKV'),
    'thes2': ('Homilien über den 2. Thessalonicherbrief', 'https://bkv.unifr.ch/de/works/cpg-4435/versions/homilien-uber-den-ii-thessalonicher-brief-bkv',
              'BKV-Ausgabe', 'BKV'),
    'tim1': ('Homilien über den 1. Timotheusbrief', 'https://bkv.unifr.ch/de/works/cpg-4436/versions/homilien-uber-den-i-brief-an-timotheus-bkv',
             'BKV-Ausgabe', 'BKV'),
    'tim2': ('Homilien über den 2. Timotheusbrief', 'https://bkv.unifr.ch/de/works/cpg-4437/versions/homilien-uber-den-ii-brief-an-timotheus-bkv',
             'BKV-Ausgabe', 'BKV'),
    'tit': ('Homilien über den Titusbrief', 'https://bkv.unifr.ch/de/works/cpg-4438/versions/homilien-uber-den-brief-an-titus-bkv',
            'BKV-Ausgabe', 'BKV'),
    'phm': ('Homilien über den Philemonbrief', 'https://bkv.unifr.ch/de/works/cpg-4439/versions/homilien-uber-den-brief-an-philemon-bkv',
            'BKV-Ausgabe', 'BKV'),
    'heb': ('Homilien über den Hebräerbrief', 'https://bkv.unifr.ch/de/works/cpg-4440/versions/homilien-uber-den-brief-an-die-hebraer-bkv',
            'BKV-Ausgabe', 'BKV'),
    'olymp': ('Briefe an Olympias und Papst Innocentius', 'https://bkv.unifr.ch/de/works/cpg-4402-4403-4405/versions/briefe-an-olympias-und-papst-innocentius',
              'BKV-Ausgabe', 'BKV'),
}


sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402


def sac_sections():
    with zipfile.ZipFile(os.path.join(ROOT, 'tmp', 'de_bkv', 'chr_sac.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for book in doc.xpath('//h2'):
        n = be.chapter_number(book) or 0
        body = ''.join(be.para_html(p) for p in book.getparent().xpath('.//p'))
        parts.append(f'<h2>{n}</h2>{body}')
    return ''.join(parts)


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def paen_sections():
    with zipfile.ZipFile(os.path.join(ROOT, 'tmp', 'de_bkv', 'chr2_paen.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    words = {'Erste': 1, 'Zweite': 2, 'Dritte': 3, 'Vierte': 4, 'Fünfte': 5,
             'Sechste': 6, 'Siebente': 7, 'Achte': 8, 'Neunte': 9}
    parts = []
    for heading in doc.xpath('//h2'):
        title = ''.join(heading.itertext()).strip()
        n = next((v for k, v in words.items() if title.startswith(k)), 0)
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        parts.append(f'<h2>{n}</h2>{body}')
    return ''.join(parts)


def bild_parts():
    with zipfile.ZipFile(os.path.join(ROOT, 'tmp', 'de_bkv', 'chr3_bild.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    words = {'Erste': 1, 'Zweite': 2, 'Dritte': 3, 'Vierte': 4, 'Fünfte': 5,
             'Sechste': 6, 'Siebente': 7, 'Achte': 8, 'Neunte': 9, 'Zehnte': 10,
             'Elfte': 11, 'Zwölfte': 12, 'Dreizehnte': 13, 'Vierzehnte': 14,
             'Fünfzehnte': 15, 'Sechzehnte': 16, 'Siebzehnte': 17,
             'Achtzehnte': 18, 'Neunzehnte': 19, 'Zwanzigste': 20,
             'Einundzwanzigste': 21}
    chapters = []
    for heading in doc.xpath('//h2'):
        title = ''.join(heading.itertext()).strip()
        n = next((v for k, v in words.items() if title.startswith(k)), 0)
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        chapters.append(f'<h2>{n}</h2>{body}')
    return ''.join(chapters[:14]), ''.join(chapters[14:])


def matt_parts():
    with zipfile.ZipFile(os.path.join(ROOT, 'tmp', 'de_bkv', 'chr4_matt.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    chapters = []
    for heading in doc.xpath('//h2'):
        n = be.chapter_number(heading) or 0
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        chapters.append(f'<h2>{n}</h2>{body}')
    cuts = [12, 12, 15, 16, 16, 19]
    parts, start = [], 0
    for c in cuts:
        parts.append(''.join(chapters[start:start + c]))
        start += c
    if start < len(chapters):
        parts[-1] += ''.join(chapters[start:])
    return parts


def rom_parts():
    with zipfile.ZipFile(os.path.join(ROOT, 'tmp', 'de_bkv', 'chr5_rom.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    chapters = []
    for heading in doc.xpath('//h2'):
        n = be.chapter_number(heading) or 0
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        chapters.append(f'<h2>{n}</h2>{body}')
    cuts = [13, 11, 9]
    parts, start = [], 0
    for c in cuts:
        parts.append(''.join(chapters[start:start + c]))
        start += c
    if start < len(chapters):
        parts[-1] += ''.join(chapters[start:])
    return parts


def cor1_parts():
    with zipfile.ZipFile(os.path.join(ROOT, 'tmp', 'de_bkv', 'chr6_cor1.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    chapters = []
    for heading in doc.xpath('//h2'):
        title = ''.join(heading.itertext()).strip()
        if title.startswith('Einleitung'):
            continue
        n = be.chapter_number(heading) or 0
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        chapters.append(f'<h2>{n}</h2>{body}')
    cuts = [16, 14, 14]
    parts, start = [], 0
    for c in cuts:
        parts.append(''.join(chapters[start:start + c]))
        start += c
    if start < len(chapters):
        parts[-1] += ''.join(chapters[start:])
    return parts


def cor2_parts():
    with zipfile.ZipFile(os.path.join(ROOT, 'tmp', 'de_bkv', 'chr7_cor2.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    chapters = []
    for heading in doc.xpath('//h2'):
        n = be.chapter_number(heading) or 0
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        chapters.append(f'<h2>{n}</h2>{body}')
    cuts = [12, 18]
    parts, start = [], 0
    for c in cuts:
        parts.append(''.join(chapters[start:start + c]))
        start += c
    if start < len(chapters):
        parts[-1] += ''.join(chapters[start:])
    return parts


def epistle_chapters(key):
    with zipfile.ZipFile(os.path.join(ROOT, 'tmp', 'de_bkv', 'chr8_' + key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    chapters = []
    for i, heading in enumerate(doc.xpath('//h2'), 1):
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        chapters.append(f'<h2>{i}</h2>{body}')
    return chapters


def epistle9(key):
    with zipfile.ZipFile(os.path.join(ROOT, 'tmp', 'de_bkv', 'chr9_' + key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    chapters = []
    for i, heading in enumerate(doc.xpath('//h2'), 1):
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        chapters.append(f'<h2>{i}</h2>{body}')
    return ''.join(chapters)


def epistle10(key):
    with zipfile.ZipFile(os.path.join(ROOT, 'tmp', 'de_bkv', 'chr10_' + key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    chapters = []
    for i, heading in enumerate(doc.xpath('//h2'), 1):
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        chapters.append(f'<h2>{i}</h2>{body}')
    return chapters


def heb_parts():
    chapters = epistle10('heb')
    return ''.join(chapters[:16]), ''.join(chapters[16:])


def eph_parts():
    chapters = epistle_chapters('eph')
    return ''.join(chapters[:17]), ''.join(chapters[17:])


def red_sections():
    with zipfile.ZipFile(os.path.join(ROOT, 'tmp', 'de_bkv', 'chr11_red.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for i, heading in enumerate(doc.xpath('//h2'), 1):
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        parts.append(f'<h2>{i}</h2>{body}')
    return ''.join(parts)


def olymp_sections():
    with zipfile.ZipFile(os.path.join(ROOT, 'tmp', 'de_bkv', 'chr2_olymp.epub')) as z:
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
    with zipfile.ZipFile(os.path.join(ROOT, 'tmp', 'de_bkv', 'chr2_' + key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    return ''.join(be.para_html(p) for p in doc.xpath('//p'))


def source(key):
    title, url, translator, edition = SOURCES[key]
    return (f'<p><strong>Quelle:</strong> Übersetzung von {translator}, '
            f'<em>{title}</em> ({edition}). Text nach '
            f'<a href="{url}">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')


def page(src, path, title, key, parent, priority, custom_body=None):
    content = custom_body if custom_body is not None else open(os.path.join(OUT, 'chr_' + key + '.html'), encoding='utf-8').read().strip()
    body = (f'<p><em>{title}, übersetzt von {SOURCES[key][2]} '
            f'({SOURCES[key][3]}).</em></p>' + content)
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
    bild1, bild2 = bild_parts()
    matt = matt_parts()
    rom = rom_parts()
    cor1 = cor1_parts()
    cor2 = cor2_parts()
    eph1, eph2 = eph_parts()
    gal = ''.join(epistle_chapters('gal'))
    phil = ''.join(epistle_chapters('phil'))
    col = epistle9('col')
    thes1 = epistle9('thes1')
    thes2 = epistle9('thes2')
    heb1, heb2 = heb_parts()
    author_html = open(AUTHOR, encoding='utf-8').read().strip()
    author = f'''# Иоанн Златоуст: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_chrysostom.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "Иоанн_Златоуст"
    path: "Johannes_Chrysostomus"
    title: "Johannes Chrysostomus, 4. Jh."
    title_sub: "Heiliger (~344–407), Erzbischof von Konstantinopel, Kirchenvater und Kirchenlehrer, bedeutender Prediger"
    copy_cover: true
    menu: {{ parent: "4. Jahrhundert", title: "Johannes Chrysostomus, Heiliger (~344–407)", replace: "Johannes Chrysostomus, Heiliger (~344–407)", priority: 6 }}
    update: true
    body: |-
{block(author_html)}
'''
    works = f'''# Иоанн Златоуст: труды (немецкая библиотека)
# Сборка: script/translations/de/build_chrysostom.py

lang: de
list: "Johannes_Chrysostomus"
folders:
  - {{ path: "Pastorale und katechetische Werke", priority: 1 }}
  - {{ path: "Moralisch-asketische Werke", priority: 2 }}
  - {{ path: "Homilien zu verschiedenen Anlässen", priority: 3 }}
  - {{ path: "Neutestamentliche Kommentare", priority: 4 }}
  - {{ path: "Briefe", priority: 5 }}
pages:

{page('wpDj_Шесть_слов_о_священстве', 'Chrysostomus_Ueber_das_Priestertum', 'Über das Priestertum', 'sac', 'Pastorale und katechetische Werke', 1, sac_sections())}
{page('fVs2_Книга_о_девстве', 'Chrysostomus_Ueber_die_Jungfraeulichkeit', 'Vom jungfräulichen Stande', 'virg', 'Moralisch-asketische Werke', 1)}
{page('tzcr_К_Феодору_падшему_увещания', 'Chrysostomus_An_Theodor', 'Erster Brief an Theodor', 'theo', 'Moralisch-asketische Werke', 2, paragraphs2('theo'))}
{page('IfGd_Беседы_о_покаянии', 'Chrysostomus_Homilien_ueber_die_Busse', 'Homilien über die Buße', 'paen', 'Moralisch-asketische Werke', 3, paen_sections())}
{page('1Eh4_Беседы_о_статуях_1', 'Chrysostomus_Bildsaeulen_1', 'Homilien über die Bildsäulen — Teil 1', 'bild', 'Homilien zu verschiedenen Anlässen', 1, bild1)}
{page('mz9c_Беседы_о_статуях_2', 'Chrysostomus_Bildsaeulen_2', 'Homilien über die Bildsäulen — Teil 2', 'bild', 'Homilien zu verschiedenen Anlässen', 2, bild2)}
{page('hLPm_Беседы_на_Евангелие_от_Матфея_1', 'Chrysostomus_Matthaeus_1', 'Homilien über das Matthäusevangelium — Teil 1', 'matt', 'Neutestamentliche Kommentare', 1, matt[0])}
{page('Hb58_Беседы_на_Евангелие_от_Матфея_2', 'Chrysostomus_Matthaeus_2', 'Homilien über das Matthäusevangelium — Teil 2', 'matt', 'Neutestamentliche Kommentare', 2, matt[1])}
{page('h6SB_Беседы_на_Евангелие_от_Матфея_3', 'Chrysostomus_Matthaeus_3', 'Homilien über das Matthäusevangelium — Teil 3', 'matt', 'Neutestamentliche Kommentare', 3, matt[2])}
{page('W5gw_Беседы_на_Евангелие_от_Матфея_4', 'Chrysostomus_Matthaeus_4', 'Homilien über das Matthäusevangelium — Teil 4', 'matt', 'Neutestamentliche Kommentare', 4, matt[3])}
{page('VmXZ_Беседы_на_Евангелие_от_Матфея_5', 'Chrysostomus_Matthaeus_5', 'Homilien über das Matthäusevangelium — Teil 5', 'matt', 'Neutestamentliche Kommentare', 5, matt[4])}
{page('QVIB_Беседы_на_Евангелие_от_Матфея_6', 'Chrysostomus_Matthaeus_6', 'Homilien über das Matthäusevangelium — Teil 6', 'matt', 'Neutestamentliche Kommentare', 6, matt[5])}
{page('bRp3_Беседы_на_Послание_к_Римлянам_1', 'Chrysostomus_Roemerbrief_1', 'Homilien über den Römerbrief — Teil 1', 'rom', 'Neutestamentliche Kommentare', 7, rom[0])}
{page('SwRt_Беседы_на_Послание_к_Римлянам_2', 'Chrysostomus_Roemerbrief_2', 'Homilien über den Römerbrief — Teil 2', 'rom', 'Neutestamentliche Kommentare', 8, rom[1])}
{page('nU7M_Беседы_на_Послание_к_Римлянам_3', 'Chrysostomus_Roemerbrief_3', 'Homilien über den Römerbrief — Teil 3', 'rom', 'Neutestamentliche Kommentare', 9, rom[2])}
{page('zieK_Беседы_на_1е_послание_к_Коринфянам_1', 'Chrysostomus_1_Korinther_1', 'Homilien über den 1. Korintherbrief — Teil 1', 'cor1', 'Neutestamentliche Kommentare', 10, cor1[0])}
{page('TBHu_Беседы_на_1е_послание_к_Коринфянам_2', 'Chrysostomus_1_Korinther_2', 'Homilien über den 1. Korintherbrief — Teil 2', 'cor1', 'Neutestamentliche Kommentare', 11, cor1[1])}
{page('HPEF_Беседы_на_1е_послание_к_Коринфянам_3', 'Chrysostomus_1_Korinther_3', 'Homilien über den 1. Korintherbrief — Teil 3', 'cor1', 'Neutestamentliche Kommentare', 12, cor1[2])}
{page('RqhH_Толкование_на_2е_послание_к_Коринфянам_1', 'Chrysostomus_2_Korinther_1', 'Homilien über den 2. Korintherbrief — Teil 1', 'cor2', 'Neutestamentliche Kommentare', 13, cor2[0])}
{page('ZIFm_Толкование_на_2е_послание_к_Коринфянам_2', 'Chrysostomus_2_Korinther_2', 'Homilien über den 2. Korintherbrief — Teil 2', 'cor2', 'Neutestamentliche Kommentare', 14, cor2[1])}
{page('nbi7_Толкование_на_послание_к_Галатам', 'Chrysostomus_Galaterbrief', 'Kommentar zum Galaterbrief', 'gal', 'Neutestamentliche Kommentare', 15, gal)}
{page('vW84_Беседы_на_послание_к_Ефесянам_1', 'Chrysostomus_Epheserbrief_1', 'Homilien über den Epheserbrief — Teil 1', 'eph', 'Neutestamentliche Kommentare', 16, eph1)}
{page('S0pr_Беседы_на_послание_к_Ефесянам_2', 'Chrysostomus_Epheserbrief_2', 'Homilien über den Epheserbrief — Teil 2', 'eph', 'Neutestamentliche Kommentare', 17, eph2)}
{page('weSI_Беседы_на_послание_к_Филиппийцам', 'Chrysostomus_Philipperbrief', 'Homilien über den Philipperbrief', 'phil', 'Neutestamentliche Kommentare', 18, phil)}
{page('LkdZ_Толкование_на_послание_к_Колоссянам', 'Chrysostomus_Kolosserbrief', 'Homilien über den Kolosserbrief', 'col', 'Neutestamentliche Kommentare', 19, col)}
{page('anSH_Толкование_на_1е_послание_к_Фессалоникийцам', 'Chrysostomus_1_Thessalonicher', 'Homilien über den 1. Thessalonicherbrief', 'thes1', 'Neutestamentliche Kommentare', 20, thes1)}
{page('ws14_Толкование_на_второе_послание_к_Фессалоникийцам', 'Chrysostomus_2_Thessalonicher', 'Homilien über den 2. Thessalonicherbrief', 'thes2', 'Neutestamentliche Kommentare', 21, thes2)}
{page('Vq7D_Толкование_на_1е_послание_к_Тимофею', 'Chrysostomus_1_Timotheus', 'Homilien über den 1. Timotheusbrief', 'tim1', 'Neutestamentliche Kommentare', 22, ''.join(epistle10('tim1')))}
{page('F9RE_Толкование_на_2е_послание_к_Тимофею', 'Chrysostomus_2_Timotheus', 'Homilien über den 2. Timotheusbrief', 'tim2', 'Neutestamentliche Kommentare', 23, ''.join(epistle10('tim2')))}
{page('jedG_Толкование_на_послание_к_Титу', 'Chrysostomus_Titus', 'Homilien über den Titusbrief', 'tit', 'Neutestamentliche Kommentare', 24, ''.join(epistle10('tit')))}
{page('b3GF_Толкование_на_послание_к_Филимону', 'Chrysostomus_Philemon', 'Homilien über den Philemonbrief', 'phm', 'Neutestamentliche Kommentare', 25, ''.join(epistle10('phm')))}
{page('yHrs_Толкование_на_послание_к_Евреям_1', 'Chrysostomus_Hebraeerbrief_1', 'Homilien über den Hebräerbrief — Teil 1', 'heb', 'Neutestamentliche Kommentare', 26, heb1)}
{page('UDdp_Толкование_на_послание_к_Евреям_2', 'Chrysostomus_Hebraeerbrief_2', 'Homilien über den Hebräerbrief — Teil 2', 'heb', 'Neutestamentliche Kommentare', 27, heb2)}
{page('eMwT_Письма_к_разным_лицам', 'Chrysostomus_Briefe_an_Olympias', 'Briefe an Olympias und Papst Innocentius (Auswahl)', 'olymp', 'Briefe', 1, olymp_sections())}
'''
    for name, text in (('chrys_author.yml', author), ('chrys_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
