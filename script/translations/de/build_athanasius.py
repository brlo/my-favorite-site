#!/usr/bin/env python3
"""Сборка немецкого Афанасия Великого: автор + три труда (BKV 1917)."""
import os
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkv_epub as be  # noqa: E402

DB = os.path.join(ROOT, 'db', 'translations', 'de')
TMP = os.path.join(ROOT, 'tmp', 'de_bkv')
OUT = os.path.join(TMP, 'out')
AUTHOR = os.path.join(ROOT, 'script', 'translations', 'de', 'authors', 'athanasius.html')

SOURCES = {
    'gent': ('Gegen die Heiden', 'https://bkv.unifr.ch/de/works/cpg-2090/versions/gegen-die-heiden-bkv',
             'Anton Stegmann und Hans Mertel', 'BKV 1. Reihe, Bd. 31, München 1917'),
    'inc': ('Über die Menschwerdung des Logos', 'https://bkv.unifr.ch/de/works/cpg-2091/versions/uber-die-menschwerdung-des-logos-und-dessen-leibliche-erscheinung-unter-uns-bkv',
            'Anton Stegmann und Hans Mertel', 'BKV 1. Reihe, Bd. 31, München 1917'),
    'vita': ('Leben des heiligen Antonius', 'https://bkv.unifr.ch/de/works/cpg-2101/versions/leben-des-heiligen-antonius-bkv',
             'Anton Stegmann und Hans Mertel', 'BKV 1. Reihe, Bd. 31, München 1917'),
    'hist': ('Geschichte der Arianer', 'https://bkv.unifr.ch/de/works/cpg-2127/versions/geschichte-der-arianer-bkv',
             'Übersetzung des 19. Jahrhunderts', 'BKV 1. Serie, Bd. 15, Kempten 1836'),
    'serap': ('Vier Briefe an Serapion von Thmuis', 'https://bkv.unifr.ch/de/works/cpg-2094/versions/vier-briefe-an-serapion-v-thmuis-bkv',
              'Übersetzung der BKV-Ausgabe', 'BKV 1. Reihe, Bd. 13, Kempten/München 1913'),
    'apol': ('Schutzschrift gegen die Arianer', 'https://bkv.unifr.ch/de/works/cpg-2123/versions/des-hl-athanasius-schutzschrift-gegen-die-arianer-bkv',
             'Jos. Fisch', 'BKV 1. Serie, Bd. 29, Kempten 1875'),
    'niz': ('Über die Beschlüsse der Synode von Nizäa', 'https://bkv.unifr.ch/de/works/cpg-2120/versions/uber-die-beschlusse-der-synode-von-nizaa-bkv',
            'Übersetzung des 19. Jahrhunderts', 'BKV 1. Serie, Bd. 14, Kempten 1836'),
    'syn': ('Abhandlung über die Synoden zu Rimini und Seleucia', 'https://bkv.unifr.ch/de/works/cpg-2128/versions/abhandlung-uber-die-synoden-zu-rimini-in-italien-und-zu-seleucia-in-isaurien-bkv',
            'Übersetzung des 19. Jahrhunderts', 'BKV 1. Serie, Bd. 16, Kempten 1836'),
    'afr': ('Brief an die Bischöfe in Afrika', 'https://bkv.unifr.ch/de/works/cpg-2133/versions/brief-an-die-bischofe-in-afrika-bkv',
            'Übersetzung des 19. Jahrhunderts', 'BKV 1. Serie, Bd. 17, Kempten 1837'),
}


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def paragraphs(key):
    with zipfile.ZipFile(os.path.join(TMP, 'ath_' + key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    return ''.join(be.para_html(p) for p in doc.xpath('//p'))


def letters(key):
    with zipfile.ZipFile(os.path.join(TMP, 'ath_' + key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for heading in doc.xpath('//h2'):
        title = ''.join(heading.itertext()).strip()
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        parts.append(f'<h2>{title}</h2>{body}')
    return ''.join(parts)


def source(key):
    title, url, translator, edition = SOURCES[key]
    return (f'<p><strong>Quelle:</strong> Übersetzung von {translator}, '
            f'<em>{title}</em> ({edition}). Text nach '
            f'<a href="{url}">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')


def page(src, path, title, key, body, priority):
    return f'''  - src: "{src}"
    path: "{path}"
    title: "{title}"
    menu: {{ parent: "Werke", title: "{title}", priority: {priority} }}
    update: true
    body: |-
{block(body)}
    references: |-
{block(source(key))}
'''


def main():
    gent = paragraphs('gent')
    inc = open(os.path.join(OUT, 'ath_inc.html'), encoding='utf-8').read().strip()
    vita = open(os.path.join(OUT, 'ath_vita.html'), encoding='utf-8').read().strip()
    hist = open(os.path.join(OUT, 'ath_hist.html'), encoding='utf-8').read().strip()
    serap = letters('serap')
    apol = open(os.path.join(OUT, 'ath_apol.html'), encoding='utf-8').read().strip()
    niz = paragraphs('niz')
    syn = paragraphs('syn')
    afr = paragraphs('afr')
    author_html = open(AUTHOR, encoding='utf-8').read().strip()
    author = f'''# Афанасий Великий: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_athanasius.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "Афанасий-Великий"
    path: "Athanasius_der_Große"
    title: "Athanasius der Große, 4. Jh."
    title_sub: "Heiliger (~295–373), Erzbischof von Alexandrien, Kirchenvater und Kirchenlehrer, Verteidiger des nicäischen Glaubens"
    copy_cover: true
    menu: {{ parent: "4. Jahrhundert", title: "Athanasius der Große, Heiliger (~295–373)", replace: "Athanasius der Große, Heiliger (~295–373)", priority: 1 }}
    update: true
    body: |-
{block(author_html)}
'''
    works = f'''# Афанасий Великий: труды (немецкая библиотека)
# Сборка: script/translations/de/build_athanasius.py

lang: de
list: "Athanasius_der_Große"
folders:
  - {{ path: "Werke", priority: 1 }}
pages:

{page('8vHZ_Слово_на_язычников', 'Athanasius_Gegen_die_Heiden', 'Gegen die Heiden', 'gent', '<p><em>Gegen die Heiden, übersetzt von Anton Stegmann und Hans Mertel (Bibliothek der Kirchenväter, 1. Reihe, Bd. 31, München 1917).</em></p>' + gent, 1)}
{page('QFHf_Слово_о_воплощении_БогаСлова', 'Athanasius_Menschwerdung', 'Über die Menschwerdung des Logos', 'inc', '<p><em>Über die Menschwerdung des Logos, übersetzt von Anton Stegmann und Hans Mertel (Bibliothek der Kirchenväter, 1. Reihe, Bd. 31, München 1917).</em></p>' + inc, 2)}
{page('5Wxn_Житие_преп_Антония_Великого', 'Athanasius_Leben_des_Antonius', 'Leben des heiligen Antonius', 'vita', '<p><em>Leben des heiligen Antonius, übersetzt von Anton Stegmann und Hans Mertel (Bibliothek der Kirchenväter, 1. Reihe, Bd. 31, München 1917).</em></p>' + vita, 3)}
{page('1wPr_История_ариан', 'Athanasius_Geschichte_der_Arianer', 'Geschichte der Arianer', 'hist', '<p><em>Geschichte der Arianer, BKV 1. Serie, Bd. 15, Kempten 1836.</em></p>' + hist, 4)}
{page('Послания_к_Серапиону_епископу_Тмуисскому', 'Athanasius_Briefe_an_Serapion', 'Vier Briefe an Serapion von Thmuis', 'serap', '<p><em>Vier Briefe an Serapion von Thmuis, BKV 1. Reihe, Bd. 13, Kempten/München 1913.</em></p>' + serap, 5)}
{page('tm9D_Защитительное_слово_против_ариан', 'Athanasius_Schutzschrift_gegen_die_Arianer', 'Schutzschrift gegen die Arianer', 'apol', '<p><em>Schutzschrift gegen die Arianer, übersetzt von Jos. Fisch (BKV 1. Serie, Bd. 29, Kempten 1875).</em></p>' + apol, 6)}
{page('pEW1_Послание_о_постановлениях_Никейского_Собора', 'Athanasius_Nizaea', 'Über die Beschlüsse der Synode von Nizäa', 'niz', '<p><em>Über die Beschlüsse der Synode von Nizäa, BKV 1. Serie, Bd. 14, Kempten 1836.</em></p>' + niz, 7)}
{page('6daQ_Послание_о_Соборах_бывших_в_Аримине_италийском_и_в_Селевкии_исаврийской', 'Athanasius_Synoden', 'Abhandlung über die Synoden zu Rimini und Seleucia', 'syn', '<p><em>Abhandlung über die Synoden zu Rimini und Seleucia, BKV 1. Serie, Bd. 16, Kempten 1836.</em></p>' + syn, 8)}
{page('qO9Y_Послание_к_Епископам_африканским', 'Athanasius_Afrikanische_Bischöfe', 'Brief an die Bischöfe in Afrika', 'afr', '<p><em>Brief an die Bischöfe in Afrika, BKV 1. Serie, Bd. 17, Kempten 1837.</em></p>' + afr, 9)}
'''
    for name, text in (('athan_author.yml', author), ('athan_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
