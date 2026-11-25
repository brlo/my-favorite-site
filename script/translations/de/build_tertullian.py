#!/usr/bin/env python3
"""Сборка немецкого Тертуллиана: автор + три трактата (Kellner 1882)."""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
DB = os.path.join(ROOT, 'db', 'translations', 'de')
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
}


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def source(key):
    title, url = SOURCES[key]
    return (f'<p><strong>Quelle:</strong> Übersetzung von Karl Adam Heinrich Kellner, '
            f'<em>{title}</em> (Tertullians sämtliche Schriften, Köln 1882). '
            f'Text nach <a href="{url}">bkv.unifr.ch</a>; die Anmerkungen der Ausgabe '
            f'sind weggelassen.</p>')


def page(src, path, title, key, priority):
    body = (f'<p><em>{title}, übersetzt von Karl Adam Heinrich Kellner (Köln 1882).</em></p>'
            + open(os.path.join(OUT, 'tert_' + key + '.html'), encoding='utf-8').read().strip())
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
'''
    for name, text in (('tert_author.yml', author), ('tert_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
