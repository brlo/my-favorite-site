#!/usr/bin/env python3
"""Сборка немецкого Григория Нисского: автор + три труда (BKV)."""
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
AUTHOR = os.path.join(ROOT, 'script', 'translations', 'de', 'authors', 'gregor_nyssa.html')

SOURCES = {
    'kate': ('Große Katechese', 'https://bkv.unifr.ch/de/works/cpg-3150/versions/grosse-katechese-bkv',
             'Übersetzung der BKV-Ausgabe', 'BKV 1. Reihe, Bd. 56, Kempten/München 1927'),
    'opif': ('Abhandlung über die Ausstattung des Menschen', 'https://bkv.unifr.ch/de/works/cpg-3154/versions/abhandlung-uber-die-ausstattung-des-menschen-bkv',
             'Heinrich Hand', 'BKV 1. Serie, Bd. 24, Kempten 1874'),
    'orat': ('Das Gebet des Herrn', 'https://bkv.unifr.ch/de/works/cpg-3160/versions/das-gebet-des-herrn-bkv',
             'Übersetzung der BKV-Ausgabe', 'BKV 1. Reihe, Bd. 56, Kempten/München 1927'),
    'beat': ('Acht Homilien über die acht Seligkeiten', 'https://bkv.unifr.ch/de/works/cpg-3161/versions/acht-homilien-uber-die-acht-seligkeiten-bkv',
             'Übersetzung der BKV-Ausgabe', 'BKV 1. Reihe, Bd. 56, Kempten/München 1927'),
    'mak': ('Lebensbeschreibung seiner Schwester Makrina', 'https://bkv.unifr.ch/de/works/cpg-3166/versions/lebensbeschreibung-seiner-schwester-makrina-bkv',
            'Übersetzung der BKV-Ausgabe', 'BKV 1. Reihe, Bd. 56, Kempten/München 1927'),
    'dial': ('Gespräch mit Makrina über Seele und Auferstehung', 'https://bkv.unifr.ch/de/works/cpg-3149/versions/gesprach-mit-makrina-uber-seele-und-auferstehung-bkv',
             'Übersetzung der BKV-Ausgabe', 'BKV 1. Reihe, Bd. 56, Kempten/München 1927'),
    'red': ('Ausgewählte Reden', 'https://bkv.unifr.ch/de/works/-44a/versions/ausgewahlte-reden-bkv',
            'Übersetzung der BKV-Ausgabe', 'BKV 1. Serie, Bd. 70'),
}
ORDINALS = {'Erste': 1, 'Zweite': 2, 'Dritte': 3, 'Vierte': 4, 'Fünfte': 5, 'Sechste': 6, 'Siebte': 7, 'Achte': 8}


def block(s):
    s = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f-\x9f]', '—', s)
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def sections(key):
    with zipfile.ZipFile(os.path.join(TMP, 'nys_' + key + '.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for heading in doc.xpath('//h2'):
        title = ''.join(heading.itertext()).strip()
        number = None
        m = re.search(r'Kapitel\s+(\d+)', title)
        if m:
            number = int(m.group(1))
        elif title.startswith('Vorwort') or title.startswith('Gregor,'):
            number = 0
        else:
            for word, value in ORDINALS.items():
                if title.startswith(word):
                    number = value
                    break
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        parts.append(f'<h2>{number if number is not None else 0}</h2>{body}')
    return ''.join(parts)


def selected_sections():
    with zipfile.ZipFile(os.path.join(TMP, 'nys_red.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    be.clean_doc(doc)
    parts = []
    for heading in doc.xpath('//h3'):
        title = ''.join(heading.itertext()).strip()
        body = ''.join(be.para_html(p) for p in heading.getparent().xpath('.//p'))
        parts.append(f'<h3>{title}</h3>{body}')
    return parts


def plain(key):
    with zipfile.ZipFile(os.path.join(TMP, 'nys_' + key + '.epub')) as z:
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


def page(src, path, title, key, priority, body=None):
    body = (f'<p><em>{title}, übersetzt von {SOURCES[key][2]} '
            f'({SOURCES[key][3]}).</em></p>' + (body if body is not None else sections(key)))
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
    beat = sections('beat')
    mak = plain('mak')
    dial = plain('dial')
    sel = selected_sections()
    author_html = open(AUTHOR, encoding='utf-8').read().strip()
    author = f'''# Григорий Нисский: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_nyssa.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "Григорий_Нисский"
    path: "Gregor_von_Nyssa"
    title: "Gregor von Nyssa, 4. Jh."
    title_sub: "Heiliger (~331–394), Bischof von Nyssa, Kirchenvater, Theologe und Mystiker"
    copy_cover: true
    menu: {{ parent: "4. Jahrhundert", title: "Gregor von Nyssa, Heiliger (~331–394)", replace: "Gregor von Nyssa, Heiliger (~331–394)", priority: 4 }}
    update: true
    body: |-
{block(author_html)}
'''
    works = f'''# Григорий Нисский: труды (немецкая библиотека)
# Сборка: script/translations/de/build_nyssa.py

lang: de
list: "Gregor_von_Nyssa"
folders:
  - {{ path: "Werke", priority: 1 }}
  - {{ path: "Predigten", priority: 2 }}
pages:

{page('L4vk_Большое_огласительное_слово', 'Gregor_Nyssa_Grosse_Katechese', 'Große Katechese', 'kate', 1)}
{page('UXHY_Об_устроении_человека', 'Gregor_Nyssa_Ausstattung_des_Menschen', 'Abhandlung über die Ausstattung des Menschen', 'opif', 2)}
{page('URHE_Беседы_о_молитве_Господней', 'Gregor_Nyssa_Gebet_des_Herrn', 'Das Gebet des Herrn', 'orat', 3)}
{page('1zoP_Беседы_о_блаженствах', 'Gregor_Nyssa_Seligkeiten', 'Acht Homilien über die acht Seligkeiten', 'beat', 4)}
{page('0Tjh_Послание_о_жизни_преподобной_Макрины', 'Gregor_Nyssa_Makrina_Leben', 'Lebensbeschreibung seiner Schwester Makrina', 'mak', 5, mak)}
{page('aCO3_О_душе_и_воскресении_Диалог_с_сестрой_Макриной', 'Gregor_Nyssa_Makrina_Gespraech', 'Gespräch mit Makrina über Seele und Auferstehung', 'dial', 6, dial)}
{page('tqun_О_нищелюбии_и_благотворительности', 'Gregor_Nyssa_Liebe_der_Armen_1', 'Erste Rede von der Liebe zu den Armen', 'red', 1, sel[0])}
{page('loBj_О_нищелюбии', 'Gregor_Nyssa_Liebe_der_Armen_2', 'Zweite Rede von der Liebe zu den Armen', 'red', 2, sel[1])}
{page('yj2I_Против_ростовщиков', 'Gregor_Nyssa_Gegen_Wucherer', 'Rede gegen die Wucherer', 'red', 3, sel[2])}
{page('2bYF_Слова_на_Святую_Пасху', 'Gregor_Nyssa_Osterpredigten', 'Predigten auf das Osterfest', 'red', 4, ''.join(sel[6:11]))}
{page('soYc_Слово_на_день_памяти_Василия_Великого_родного_брата', 'Gregor_Nyssa_Rede_auf_Basilius', 'Rede auf seinen Bruder Basilius', 'red', 5, sel[13])}
{page('R1rv_Похвальное_слово_великомученику_Феодору_Тирону', 'Gregor_Nyssa_Lobrede_Theodor', 'Lobrede auf den großen Märtyrer Theodor', 'red', 6, sel[18])}
{page('4Z0l_Слово_На_Рождество_Господа_нашего_Иисуса_Христа_и_на_избиение_младенцев_в_Вифлееме_от_Ирода', 'Gregor_Nyssa_Rede_auf_Weihnachten', 'Rede auf die Geburt Christi', 'red', 7, sel[4])}
{page('fBzJ_Слово_на_Вознесение', 'Gregor_Nyssa_Rede_auf_Himmelfahrt', 'Rede auf die Himmelfahrt', 'red', 8, sel[11])}
{page('3LKW_Похвальное_слово_святым_сорока_мученикам_1е', 'Gregor_Nyssa_Lobrede_40_Maertyrer_1', 'Erste Lobrede auf die vierzig Märtyrer', 'red', 9, sel[14])}
{page('9ZOT_Похвальное_слово_святым_сорока_мученикам_2е', 'Gregor_Nyssa_Lobrede_40_Maertyrer_2', 'Zweite Lobrede auf die vierzig Märtyrer', 'red', 10, sel[15])}
{page('JHwC_Похвальное_слово_святым_сорока_мученикам_произнесенное_во_храме_их', 'Gregor_Nyssa_Lobrede_40_Maertyrer_3', 'Dritte Lobrede auf die vierzig Märtyrer', 'red', 11, sel[16])}
{page('vDPu_На_слова_Писанияа_блудяй_во_свое_тело_согрешает_1Кор_618', 'Gregor_Nyssa_Rede_gegen_die_Unzucht', 'Rede über die Worte: Der Unzüchtige sündigt gegen seinen eigenen Leib', 'red', 12, sel[3])}
{page('jSMf_Похвальное_слово_преподобному_отцу_нашему_Ефрему', 'Gregor_Nyssa_Lobrede_Ephraem', 'Lobrede auf unseren heiligen Vater Ephräm', 'red', 13, sel[17])}
{page('NZHV_Слово_о_жизни_святого_Григория_Чудотворца', 'Gregor_Nyssa_Leben_Gregors_des_Wundertäters', 'Rede über das Leben des heiligen Gregor des Wundertäters', 'red', 14, sel[19])}
{page('aVWg_Слово_на_день_Светов_в_который_крестился_наш_Господь', 'Gregor_Nyssa_Rede_auf_die_Erscheinung', 'Rede auf den Festtag der Lichter', 'red', 15, sel[5])}
{page('qJW9_Надгробное_слово_Мелетию_Великому_епископу_Антиохийскому', 'Gregor_Nyssa_Trauerrede_Meletius', 'Trauerrede auf Meletius, Bischof von Antiochien', 'red', 16, sel[20])}
'''
    for name, text in (('nyssa_author.yml', author), ('nyssa_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
