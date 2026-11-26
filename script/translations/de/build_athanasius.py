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
    'jov': ('Brief an Kaiser Jovian', 'https://bkv.unifr.ch/de/works/cpg-2135/versions/brief-an-den-kaiser-jovianus-bkv',
            'Übersetzung des 19. Jahrhunderts', 'BKV'),
    'max': ('Brief an den Philosophen Maximus', 'https://bkv.unifr.ch/de/works/cpg-2100/versions/brief-an-den-philosophen-maximus-bkv',
            'Übersetzung des 19. Jahrhunderts', 'BKV'),
    'drac': ('Brief an Dracontius', 'https://bkv.unifr.ch/de/works/cpg-2132/versions/unseres-heiligen-vaters-athanasius-erzbischofes-von-alexandrien-brief-an-den-dracontius-bkv',
             'Übersetzung des 19. Jahrhunderts', 'BKV'),
    'ruf': ('Brief an Rufinianus', 'https://bkv.unifr.ch/de/works/cpg-2107/versions/brief-an-den-rufinianus-bkv',
            'Übersetzung des 19. Jahrhunderts', 'BKV'),
    'marc': ('Brief an Marcellinus über die Erklärung der Psalmen', 'https://bkv.unifr.ch/de/works/cpg-2097/versions/des-hl-athanasius-brief-an-marcellinus-uber-die-erklarung-der-psalmen-bkv',
             'Übersetzung des 19. Jahrhunderts', 'BKV'),
    'tom': ('Schreiben an die Antiochener', 'https://bkv.unifr.ch/de/works/cpg-2134/versions/schreiben-an-die-antiochier-bkv',
            'Übersetzung des 19. Jahrhunderts', 'BKV'),
    'enc': ('Umlaufschreiben', 'https://bkv.unifr.ch/de/works/cpg-2124/versions/umlaufschreiben-des-heiligen-athanasius-bischofs-von-alexandrien-bkv',
            'Übersetzung des 19. Jahrhunderts', 'BKV'),
    'aeg': ('Rundschreiben an die Bischöfe Ägyptens und Libyens', 'https://bkv.unifr.ch/de/works/cpg-2092/versions/rundschreiben-an-die-bischofe-agyptens-und-libyens-bkv',
            'Übersetzung des 19. Jahrhunderts', 'BKV'),
    'arian': ('Vier Reden gegen die Arianer', 'https://bkv.unifr.ch/de/works/cpg-2093/versions/vier-reden-gegen-die-arianer-bkv',
              'Übersetzung des 19. Jahrhunderts', 'BKV'),
    'const': ('Schutzschrift an Kaiser Constantius', 'https://bkv.unifr.ch/de/works/cpg-2129/versions/des-hl-athanasius-schutzschrift-an-kaiser-constantius-bkv',
              'Übersetzung des 19. Jahrhunderts', 'BKV'),
    'fuga': ('Rechtfertigung wegen seiner Entweichung', 'https://bkv.unifr.ch/de/works/cpg-2122/versions/rechtfertigung-wegen-seiner-entweichung-bkv',
             'Übersetzung des 19. Jahrhunderts', 'BKV'),
    'dion': ('Verteidigung der Lehre des heiligen Dionysius von Alexandrien', 'https://bkv.unifr.ch/de/works/cpg-2121/versions/vertheidigung-der-lehre-des-heiligen-dionysius-von-alexandrien-bkv',
             'Übersetzung des 19. Jahrhunderts', 'BKV'),
    'ps': ('Erklärung der Psalmen', 'https://bkv.unifr.ch/de/works/cpg-2140/versions/des-hl-athanasius-erklarung-der-psalmen-bkv',
           'Übersetzung des 19. Jahrhunderts', 'BKV'),
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


def ps_parts():
    with zipfile.ZipFile(os.path.join(TMP, 'ath_ps.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    chapters = []
    for heading in doc.xpath('//h2'):
        title = ''.join(heading.itertext()).strip()
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        chapters.append(f'<h2>{title}</h2>{body}')
    cuts = [59, 54]
    parts, start = [], 0
    for c in cuts:
        parts.append(''.join(chapters[start:start + c]))
        start += c
    parts.append(''.join(chapters[start:]))
    return parts


def paragraphs3(key):
    with zipfile.ZipFile(os.path.join(TMP, 'ath3_' + key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    return ''.join(be.para_html(p) for p in doc.xpath('//p'))


def paragraphs2(key):
    with zipfile.ZipFile(os.path.join(TMP, 'ath2_' + key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    return ''.join(be.para_html(p) for p in doc.xpath('//p'))


def arian_parts():
    with zipfile.ZipFile(os.path.join(TMP, 'ath_arian.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for heading in doc.xpath('//h2'):
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        parts.append(body)
    return parts


def source(key):
    title, url, translator, edition = SOURCES[key]
    return (f'<p><strong>Quelle:</strong> Übersetzung von {translator}, '
            f'<em>{title}</em> ({edition}). Text nach '
            f'<a href="{url}">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe sind weggelassen.</p>')


def page(src, path, title, key, body, priority, parent="Werke"):
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
{page('c8Pb_Послание_к_императору_Иовиану', 'Athanasius_Brief_an_Jovian', 'Brief an Kaiser Jovian', 'jov', '<p><em>Brief an Kaiser Jovian (Bibliothek der Kirchenväter).</em></p>' + paragraphs('jov'), 10)}
{page('DfGH_Послание_к_Максиму_философу', 'Athanasius_Brief_an_Maximus', 'Brief an den Philosophen Maximus', 'max', '<p><em>Brief an den Philosophen Maximus (Bibliothek der Kirchenväter).</em></p>' + paragraphs('max'), 11)}
{page('YB7w_Письмо_к_Драконтию', 'Athanasius_Brief_an_Dracontius', 'Brief an Dracontius', 'drac', '<p><em>Brief an Dracontius (Bibliothek der Kirchenväter).</em></p>' + paragraphs('drac'), 12)}
{page('TLhd_Послание_к_Руфиниану', 'Athanasius_Brief_an_Rufinianus', 'Brief an Rufinianus', 'ruf', '<p><em>Brief an Rufinianus (Bibliothek der Kirchenväter).</em></p>' + paragraphs('ruf'), 13)}
{page('Hs9M_Послание_к_Маркеллину_об_истолковании_псалмов', 'Athanasius_Brief_an_Marcellinus', 'Brief an Marcellinus über die Erklärung der Psalmen', 'marc', '<p><em>Brief an Marcellinus (Bibliothek der Kirchenväter).</em></p>' + paragraphs2('marc'), 14)}
{page('IqXZ_Свиток_к_антиохийцам', 'Athanasius_Tomus_an_die_Antiochener', 'Schreiben an die Antiochener', 'tom', '<p><em>Schreiben an die Antiochener (Bibliothek der Kirchenväter).</em></p>' + paragraphs2('tom'), 15)}
{page('AUEs_Окружное_послание', 'Athanasius_Enzyklika', 'Umlaufschreiben', 'enc', '<p><em>Umlaufschreiben (Bibliothek der Kirchenväter).</em></p>' + paragraphs2('enc'), 16)}
{page('09Ig_К_епископам_Египта_и_Ливии_окружное_послание_противариан', 'Athanasius_Brief_an_die_Bischoefe_Aegyptens', 'Rundschreiben an die Bischöfe Ägyptens und Libyens', 'aeg', '<p><em>Rundschreiben an die Bischöfe Ägyptens und Libyens (Bibliothek der Kirchenväter).</em></p>' + paragraphs2('aeg'), 17)}
{page('94wo_Защитительное_слово_Афанасия_архиепископа_александрийского_перед_царем_Констанцием', 'Athanasius_Schutzschrift_an_Constantius', 'Schutzschrift an Kaiser Constantius', 'const', '<p><em>Schutzschrift an Kaiser Constantius (Bibliothek der Kirchenväter).</em></p>' + paragraphs3('const'), 1, 'Apologetische Werke')}
{page('RyeG_Защитительное_слово_в_котором_Свт_Афанасий_оправдывает_бегство_свое_во_время_гонения_произведенного_дуком_Сирианом', 'Athanasius_Rechtfertigung_der_Flucht', 'Rechtfertigung wegen seiner Entweichung', 'fuga', '<p><em>Rechtfertigung wegen seiner Entweichung (Bibliothek der Kirchenväter).</em></p>' + paragraphs3('fuga'), 2, 'Apologetische Werke')}
{page('3aoc_О_Дионисии_епископе_Александрийском', 'Athanasius_Dionysius', 'Verteidigung der Lehre des heiligen Dionysius von Alexandrien', 'dion', '<p><em>Verteidigung der Lehre des heiligen Dionysius (Bibliothek der Kirchenväter).</em></p>' + paragraphs3('dion'), 5, 'Dogmatisch-polemische Werke')}
{page('p9R4_Толкование_на_псалмы_1', 'Athanasius_Psalmen_1', 'Erklärung der Psalmen — Teil 1', 'ps', '<p><em>Erklärung der Psalmen (Bibliothek der Kirchenväter).</em></p>' + ps_parts()[0], 1, 'Exegetische Werke')}
{page('ayQH_Толкование_на_псалмы_2', 'Athanasius_Psalmen_2', 'Erklärung der Psalmen — Teil 2', 'ps', '<p><em>Erklärung der Psalmen (Bibliothek der Kirchenväter).</em></p>' + ps_parts()[1], 2, 'Exegetische Werke')}
{page('m0JX_Толкование_на_псалмы_3', 'Athanasius_Psalmen_3', 'Erklärung der Psalmen — Teil 3', 'ps', '<p><em>Erklärung der Psalmen (Bibliothek der Kirchenväter).</em></p>' + ps_parts()[2], 3, 'Exegetische Werke')}
'''
    arian = f'''# Афанасий: четыре слова против ариан (EN-оригинал)
lang: de
src_lang: "en"
list: "Athanasius_der_Große"
pages:

{page('athanasius-four-discourses-against-the-arians-1', 'Athanasius_Gegen_die_Arianer_1', 'Erste Rede gegen die Arianer', 'arian', '<p><em>Erste Rede gegen die Arianer (Bibliothek der Kirchenväter).</em></p>' + arian_parts()[0], 1, 'Dogmatisch-polemische Werke')}
{page('athanasius-four-discourses-against-the-arians-2', 'Athanasius_Gegen_die_Arianer_2', 'Zweite Rede gegen die Arianer', 'arian', '<p><em>Zweite Rede gegen die Arianer (Bibliothek der Kirchenväter).</em></p>' + arian_parts()[1], 2, 'Dogmatisch-polemische Werke')}
{page('athanasius-four-discourses-against-the-arians-3', 'Athanasius_Gegen_die_Arianer_3', 'Dritte Rede gegen die Arianer', 'arian', '<p><em>Dritte Rede gegen die Arianer (Bibliothek der Kirchenväter).</em></p>' + arian_parts()[2], 3, 'Dogmatisch-polemische Werke')}
{page('athanasius-four-discourses-against-the-arians-4', 'Athanasius_Gegen_die_Arianer_4', 'Vierte Rede gegen die Arianer', 'arian', '<p><em>Vierte Rede gegen die Arianer (Bibliothek der Kirchenväter).</em></p>' + arian_parts()[3], 4, 'Dogmatisch-polemische Werke')}
'''
    for name, text in (('athan_author.yml', author), ('athan_works.yml', works), ('athan_arian.yml', arian)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
