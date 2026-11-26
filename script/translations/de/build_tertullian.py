#!/usr/bin/env python3
"""Сборка немецкого Тертуллиана: автор + три трактата (Kellner 1882)."""
import os
import sys
import zipfile
from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
DB = os.path.join(ROOT, 'db', 'translations', 'de')
TMP = os.path.join(ROOT, 'tmp', 'de_bkv')
OUT = os.path.join(ROOT, 'tmp', 'de_bkv', 'out')
AUTHOR = os.path.join(ROOT, 'script', 'translations', 'de', 'authors', 'tertullian.html')

SOURCES = {
    'caro': ('Über den Leib Christi', 'https://bkv.unifr.ch/de/works/cpl-18/versions/uber-den-leib-christi-bkv'),
    'res': ('Über die Auferstehung des Fleisches', 'https://bkv.unifr.ch/de/works/CPL-19/versions/uber-die-auferstehung-des-fleisches-bkv'),
    'anima': ('Über die Seele', 'https://bkv.unifr.ch/de/works/cpl-17/versions/uber-die-seele-bkv'),
    'prax': ('Gegen Praxeas', 'https://bkv.unifr.ch/de/works/cpl-26/versions/gegen-praxeas-bkv'),
    'apol': ('Apologeticum', 'https://bkv.unifr.ch/de/works/cpl-3/versions/apologetikum-bkv'),
    'bapt': ('Über die Taufe', 'https://bkv.unifr.ch/de/works/cpl-8/versions/uber-die-taufe-bkv'),
    'prae': ('Die Prozesseinreden gegen die Häretiker', 'https://bkv.unifr.ch/de/works/cpl-5/versions/die-prozesseinreden-gegen-die-haretiker-bkv'),
    'cor': ('Vom Kranze des Soldaten', 'https://bkv.unifr.ch/de/works/cpl-21/versions/vom-kranze-des-soldaten-bkv'),
    'idol': ('Über den Götzendienst', 'https://bkv.unifr.ch/de/works/cpl-23/versions/uber-den-gotzendienst-bkv'),
    'orat': ('Über das Gebet', 'https://bkv.unifr.ch/de/works/cpl-7/versions/uber-das-gebet-bkv'),
    'pat': ('Über die Geduld', 'https://bkv.unifr.ch/de/works/cpl-9/versions/uber-die-geduld-bkv'),
    'paen': ('Über die Buße', 'https://bkv.unifr.ch/de/works/cpl-10/versions/uber-die-busse-bkv'),
    'uxor': ('An die Gattin', 'https://bkv.unifr.ch/de/works/cpl-12/versions/tert-uxor-bkv'),
    'iud': ('Gegen die Juden', 'https://bkv.unifr.ch/de/works/cpl-33/versions/gegen-die-juden-bkv'),
    'spec': ('Über die Schauspiele', 'https://bkv.unifr.ch/de/works/cpl-6/versions/uber-die-schauspiele-bkv'),
    'mart': ('An die Märtyrer', 'https://bkv.unifr.ch/de/works/cpl-1/versions/tert-mart-bkv'),
    'scap': ('An Scapula', 'https://bkv.unifr.ch/de/works/cpl-24/versions/an-scapula-bkv'),
    'test': ('Das Zeugnis der Seele', 'https://bkv.unifr.ch/de/works/cpl-4/versions/das-zeugnis-der-seele-bkv'),
    'herm': ('Gegen Hermogenes', 'https://bkv.unifr.ch/de/works/cpl-13/versions/gegen-hermogenes-bkv'),
    'val': ('Gegen die Valentinianer', 'https://bkv.unifr.ch/de/works/cpl-16/versions/gegen-die-valentinianer-bkv'),
    'scorp': ('Arznei gegen den Skorpionstich', 'https://bkv.unifr.ch/de/works/cpl-22/versions/arznei-gegen-skorpionstich-bkv'),
    'pall': ('Über das Pallium oder den Philosophenmantel', 'https://bkv.unifr.ch/de/works/cpl-15/versions/uber-das-pallium-oder-den-philosophenmantel-bkv'),
    'fuga': ('Über das Fliehen in der Verfolgung', 'https://bkv.unifr.ch/de/works/cpl-25/versions/uber-das-fliehen-in-der-verfolgung-bkv'),
    'mono': ('Über die einmalige Ehe', 'https://bkv.unifr.ch/de/works/cpl-28/versions/uber-die-einmalige-ehe-bkv'),
    'cast': ('Über die Aufforderung zur Keuschheit', 'https://bkv.unifr.ch/de/works/cpl-20/versions/uber-die-aufforderung-zur-keuschheit-bkv'),
    'ieiun': ('Über das Fasten gegen die Psychiker', 'https://bkv.unifr.ch/de/works/cpl-29/versions/uber-das-fasten-gegen-die-psychiker-bkv'),
    'virg': ('Über die Verschleierung der Jungfrauen', 'https://bkv.unifr.ch/de/works/cpl-27/versions/uber-die-verschleierung-der-jungfrauen-bkv'),
    'pud': ('Über die Ehrbarkeit', 'https://bkv.unifr.ch/de/works/cpl-30/versions/uber-die-ehrbarkeit-bkv'),
    'cult': ('Über den weiblichen Putz', 'https://bkv.unifr.ch/de/works/cpl-11/versions/uber-den-weiblichen-putz-bkv'),
}


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def source(key):
    title, url = SOURCES[key]
    return (f'<p><strong>Quelle:</strong> Übersetzung von Karl Adam Heinrich Kellner, '
            f'<em>{title}</em> (Tertullians sämtliche Schriften, Köln 1882). '
            f'Text nach <a href="{url}">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe '
            f'sind weggelassen.</p>')


def uxor_sections():
    with zipfile.ZipFile(os.path.join(TMP, 'tert5_uxor.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    import bkv_epub as be
    be.clean_doc(doc)
    parts = []
    for book in doc.xpath('//h2'):
        number = ''.join(book.itertext()).strip().split()[0]
        parts.append(f'<h2>Teil {number}</h2>')
        for chapter in book.getparent().xpath('./section'):
            heading = chapter.find('h3')
            n = be.chapter_number(heading) if heading is not None else None
            body = ''.join(be.para_html(p) for p in chapter.xpath('.//p'))
            if body:
                parts.append(f'<h2>{n if n is not None else 0}</h2>{body}')
    return ''.join(parts)


def cult_books():
    with zipfile.ZipFile(os.path.join(TMP, 'tert10_cult.epub')) as z:
        name = max([n for n in z.namelist() if n.startswith('EPUB/text/')],
                   key=lambda n: z.getinfo(n).file_size)
        doc = LH.fromstring(z.read(name))
    import bkv_epub as be
    be.clean_doc(doc)
    result = []
    for book in doc.xpath('//h2'):
        parts = []
        for chapter in book.getparent().xpath('./section'):
            heading = chapter.find('h3')
            n = be.chapter_number(heading) if heading is not None else None
            body = ''.join(be.para_html(p) for p in chapter.xpath('.//p'))
            if body:
                parts.append(f'<h2>{n if n is not None else 0}</h2>{body}')
        result.append(''.join(parts))
    return result


def page(src, path, title, key, priority, custom_body=None):
    body = (f'<p><em>{title}, übersetzt von Karl Adam Heinrich Kellner (Köln 1882).</em></p>'
            + (custom_body if custom_body is not None else open(os.path.join(OUT, 'tert_' + key + '.html'), encoding='utf-8').read().strip()))
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
    cult1, cult2 = cult_books()
    author_html = open(AUTHOR, encoding='utf-8').read().strip()
    author = f'''# Тертуллиан: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_tertullian.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "тертуллиан"
    path: "Tertullian"
    title: "Tertullian, 2.–3. Jh."
    title_sub: "(~155–220) einer der hervorragenden frühchristlichen Schriftsteller, Apologeten und Polemiker. Begründete die lateinische Patristik und die kirchliche Latinität. Später neigte er zur montanistischen Häresie."
    copy_cover: true
    menu: {{ parent: "2. Jahrhundert", title: "Tertullian (~155–220)", replace: "Tertullian (~155–220)", priority: 20 }}
    update: true
    body: |-
{block(author_html)}
'''
    works = f'''# Тертуллиан: труды (немецкая библиотека)
# Сборка: script/translations/de/build_tertullian.py

lang: de
list: "Tertullian"
folders:
  - {{ path: "Werke", priority: 1 }}
pages:

{page('aI3W_О_плоти_Христа', 'Tertullian_De_carne_Christi', 'Über den Leib Christi', 'caro', 1)}
{page('pdqe_О_воскресении_плоти', 'Tertullian_De_resurrectione_carnis', 'Über die Auferstehung des Fleisches', 'res', 2)}
{page('XyG2_О_душе_1', 'Tertullian_De_anima', 'Über die Seele', 'anima', 3)}
{page('Enzr_Против_Праксея', 'Tertullian_Adversus_Praxean', 'Gegen Praxeas', 'prax', 4)}
{page('cjtQ_Апологетик', 'Tertullian_Apologeticum', 'Apologeticum', 'apol', 5)}
{page('9JXy_О_крещении', 'Tertullian_De_baptismo', 'Über die Taufe', 'bapt', 6)}
{page('37Jr_О_прескрипции_против_еретиков_1', 'Tertullian_De_praescriptione', 'Die Prozesseinreden gegen die Häretiker', 'prae', 7)}
{page('iPSC_О_венце_воина', 'Tertullian_De_corona', 'Vom Kranze des Soldaten', 'cor', 8)}
{page('cVDs_Об_идолопоклонстве', 'Tertullian_De_idololatria', 'Über den Götzendienst', 'idol', 9)}
{page('S9zX_О_молитве', 'Tertullian_De_oratione', 'Über das Gebet', 'orat', 10)}
{page('NdP5_О_терпении', 'Tertullian_De_patientia', 'Über die Geduld', 'pat', 11)}
{page('JqFh_О_покаянии', 'Tertullian_De_paenitentia', 'Über die Buße', 'paen', 12)}
{page('wUzN_Послание_к_жене', 'Tertullian_Ad_uxorem', 'An die Gattin', 'uxor', 13, uxor_sections())}
{page('oZSL_Против_иудеев', 'Tertullian_Adversus_Iudaeos', 'Gegen die Juden', 'iud', 14)}
{page('Vyit_О_зрелищах', 'Tertullian_De_spectaculis', 'Über die Schauspiele', 'spec', 15)}
{page('WbSq_Послание_к_мученикам', 'Tertullian_Ad_martyres', 'An die Märtyrer', 'mart', 16)}
{page('wb6X_К_Скапуле', 'Tertullian_Ad_Scapulam', 'An Scapula', 'scap', 17)}
{page('JYEk_О_свидетельстве_души', 'Tertullian_De_testimonio_animae', 'Das Zeugnis der Seele', 'test', 18)}
{page('dINv_Против_Гермогена_1', 'Tertullian_Adversus_Hermogenem', 'Gegen Hermogenes', 'herm', 19)}
{page('n4PQ_Против_Валентиниан', 'Tertullian_Adversus_Valentinianos', 'Gegen die Valentinianer', 'val', 20)}
{page('QvjN_Скорпиак_или_противоядие_от_угрызения_скорпионов', 'Tertullian_Scorpiace', 'Arznei gegen den Skorpionstich', 'scorp', 21)}
{page('XOpx_О_плаще', 'Tertullian_De_pallio', 'Über das Pallium oder den Philosophenmantel', 'pall', 22)}
{page('iRVv_О_бегстве_во_время_гонений', 'Tertullian_De_fuga', 'Über das Fliehen in der Verfolgung', 'fuga', 23)}
{page('4xbT_О_единоженстве', 'Tertullian_De_monogamia', 'Über die einmalige Ehe', 'mono', 24)}
{page('yTgS_О_целомудрии', 'Tertullian_De_exhortatione_castitatis', 'Über die Aufforderung zur Keuschheit', 'cast', 25)}
{page('NqoW_О_посте', 'Tertullian_De_ieiunio', 'Über das Fasten gegen die Psychiker', 'ieiun', 26)}
{page('2dNZ_О_покрывале_девственниц', 'Tertullian_De_virginibus_velandis', 'Über die Verschleierung der Jungfrauen', 'virg', 27)}
{page('wvx9_О_стыдливости_De_Pudicitia', 'Tertullian_De_pudicitia', 'Über die Ehrbarkeit', 'pud', 30)}
{page('ZF4v_О_женских_украшениях__книга_1', 'Tertullian_De_cultu_feminarum_1', 'Über den weiblichen Putz — Buch 1', 'cult', 28, cult1)}
{page('EQVa_О_женских_украшениях', 'Tertullian_De_cultu_feminarum_2', 'Über den weiblichen Putz — Buch 2', 'cult', 29, cult2)}
'''
    for name, text in (('tert_author.yml', author), ('tert_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
