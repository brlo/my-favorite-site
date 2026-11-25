#!/usr/bin/env python3
"""BKV-EPUB -> HTML-фрагменты для святоотеческой библиотеки (немецкий раздел).

Источник — EPUB с bkv.unifr.ch (Bibliothek der Kirchenväter, Kösel 1911–1938;
переводы Franz Zeller, Gerhard Rauschen и др., общественное достояние).

Что делает:
  * снимает ссылки на сканы страниц («S. 25») и сноски BKV (номера в тексте и
    список в конце), потому что для сайта берём только текст перевода;
  * заголовки глав («1. Kap. …») сводит к номеру главы: <h2>1</h2> — из них
    HtmlRenderer строит якоря #HH-1;
  * вступление/приветствие до первой главы отдаёт как <h2>0</h2>;
  * у Игнатия режет том на 7 писем (section level2 = письмо).

Запуск: python3 script/translations/de/bkv_epub.py
Пишет tmp/de_bkv/out/<key>.html и tmp/de_bkv/out/manifest.json.
"""
import json
import os
import re
import zipfile

from lxml import html as LH

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
TMP = os.path.join(ROOT, 'tmp', 'de_bkv')
OUT = os.path.join(TMP, 'out')

# ключ EPUB -> как резать
SOURCES = {
    'clem1': {'mode': 'chapters'},
    'clem2': {'mode': 'chapters'},
    'polyk': {'mode': 'chapters'},
    'ign': {'mode': 'letters'},
    'minuc': {'mode': 'chapters'},
    'arist': {'mode': 'chapters'},
    'diog': {'mode': 'chapters'},
    'athen_res': {'mode': 'chapters'},
    'athen_supp': {'mode': 'chapters'},
    'barn': {'mode': 'chapters'},
    'did': {'mode': 'chapters'},
}

FOOTNOTE_DEF = re.compile(r'\[\^\d+\]:.*$', re.S)
FOOTNOTE_REF = re.compile(r'\[\^\d+\]')


def load_epub(key):
    path = os.path.join(TMP, key + '.epub')
    with zipfile.ZipFile(path) as z:
        names = [n for n in z.namelist() if re.fullmatch(r'EPUB/text/ch\d+\.xhtml', n)]
        # ch001 — титульная страница, текст всегда в самом большом файле
        name = max(names, key=lambda n: z.getinfo(n).file_size)
        return LH.fromstring(z.read(name))


def clean_doc(doc):
    # список сносок в конце тома
    for section in doc.xpath('//section[contains(concat(" ", normalize-space(@class), " "), " footnotes ")]'):
        section.getparent().remove(section)
    # ссылки на сканы страниц («S. 25») и маркеры сносок
    for a in list(doc.xpath('//a')):
        href = a.get('href') or ''
        cls = a.get('class') or ''
        if '/scans/' in href or 'footnote-ref' in cls or 'footnote-back' in cls:
            a.drop_tree()  # снимает элемент вместе с «S. 25»/номером, хвост сохраняет
    # определения сносок в тексте (pandoc-остатки вида «[^1]: Spr 3:34»)
    for p in doc.xpath('//p'):
        text = p.text or ''
        if '[^' in ''.join(p.itertext()):
            # обрезаем параграф по первому определению сноски — оно всегда в хвосте
            for child in list(p):
                p.remove(child)
                p.text = (p.text or '') + (child.tail or '')
            p.text = FOOTNOTE_DEF.sub('', p.text or '')
            p.text = FOOTNOTE_REF.sub('', p.text)
    for el in doc.xpath('//*[not(self::script) and not(self::style)]'):
        if el.text:
            el.text = FOOTNOTE_REF.sub('', el.text)
        if el.tail:
            el.tail = FOOTNOTE_REF.sub('', el.tail)


def para_html(p):
    s = LH.tostring(p, encoding='unicode', method='html', with_tail=False)
    # оставляем только сам <p>, без обёртки
    m = re.fullmatch(r'<p[^>]*>(.*)</p>', s, re.S)
    inner = m.group(1) if m else s
    inner = inner.replace('\u00a0', ' ')
    inner = re.sub(r'\s+', ' ', inner).strip()
    inner = re.sub(r'\s+([.,;:!?])', r'\1', inner)
    return '<p>%s</p>' % inner


ROMAN = {'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100, 'D': 500, 'M': 1000}


def roman_number(text):
    total = 0
    prev = 0
    for ch in reversed(text.upper()):
        value = ROMAN.get(ch, 0)
        total += -value if value < prev else value
        prev = max(prev, value)
    return total


def chapter_number(heading):
    text = ''.join(heading.itertext()).strip()
    m = re.match(r'(\d+)\.', text)
    if m:
        return int(m.group(1))
    m = re.match(r'([IVXLCDM]+)\.', text)
    if m:
        return roman_number(m.group(1))
    return None


def chapters_html(container):
    """Все главы контейнера -> [(номер, html)] + текст до первой главы."""
    intro = []
    chapters = []
    for child in container.iterchildren():
        if child.tag == 'p':
            intro.append(para_html(child))
        elif child.tag == 'section' and 'level2' in (child.get('class') or ''):
            h = child.find('h2')
            n = chapter_number(h) if h is not None else None
            body = ''.join(para_html(p) for p in child.iterchildren() if p.tag == 'p')
            if n is not None:
                chapters.append((n, body))
    return intro, chapters


def letter_html(letter_section):
    intro = []
    chapters = []
    for child in letter_section.iterchildren():
        if child.tag == 'p':
            intro.append(para_html(child))
        elif child.tag == 'section' and 'level3' in (child.get('class') or ''):
            h = child.find('h3')
            n = chapter_number(h) if h is not None else None
            body = ''.join(para_html(p) for p in child.iterchildren() if p.tag == 'p')
            if n is not None:
                chapters.append((n, body))
    return intro, chapters


def render(intro, chapters):
    parts = []
    if intro:
        parts.append('<h2>0</h2>' + ''.join(intro))
    for n, body in sorted(chapters, key=lambda x: x[0]):
        parts.append('<h2>%d</h2>%s' % (n, body))
    return '\n'.join(parts)


def main():
    os.makedirs(OUT, exist_ok=True)
    manifest = {}

    for key, cfg in SOURCES.items():
        doc = load_epub(key)
        clean_doc(doc)
        level1 = doc.xpath('//section[contains(concat(" ", normalize-space(@class), " "), " level1 ")]')[0]

        if cfg['mode'] == 'chapters':
            intro, chapters = chapters_html(level1)
            html = render(intro, chapters)
            path = os.path.join(OUT, key + '.html')
            with open(path, 'w', encoding='utf-8') as f:
                f.write(html)
            manifest[key] = {'length': len(html), 'chapters': len(chapters),
                             'first': chapters[0][0] if chapters else None,
                             'last': chapters[-1][0] if chapters else None}
            print(key, len(html), 'chapters', len(chapters), 'range',
                  (chapters[0][0], chapters[-1][0]) if chapters else None)
        else:
            for letter in level1.xpath('./section[contains(concat(" ", normalize-space(@class), " "), " level2 ")]'):
                title = ''.join(letter.find('h2').itertext()).strip()
                intro, chapters = letter_html(letter)
                html = render(intro, chapters)
                slug = re.sub(r'[^a-z]+', '-', title.lower()).strip('-')
                key2 = 'ign-' + slug
                with open(os.path.join(OUT, key2 + '.html'), 'w', encoding='utf-8') as f:
                    f.write(html)
                manifest[key2] = {'length': len(html), 'chapters': len(chapters), 'title': title}
                print(key2, len(html), 'chapters', len(chapters), '|', title)

    with open(os.path.join(OUT, 'manifest.json'), 'w', encoding='utf-8') as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)


if __name__ == '__main__':
    main()
