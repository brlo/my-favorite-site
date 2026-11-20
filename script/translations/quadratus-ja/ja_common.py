#!/usr/bin/env python3
# Общие помощники для ja-перевода страницы Кодрата (tmp/ja_fathers/quadratus/ja_author.py).
# По образцу polycarp-ja / clement-ja: список автора — chirch_writers_jp (827),
# меню — пункт «1世紀»; заготовку クアドラトゥス（1世紀～2世紀） заменяем.
import os
import re


def _book_abbrs():
    """Короткие названия книг из config/locales/ja.yml (books.short)"""
    text = open(os.path.join(os.path.dirname(__file__), '..', '..', '..', 'config/locales/ja.yml')).read()
    block = text.split('\n  books:\n    short:\n', 1)[1].split('\n    mid:', 1)[0]
    return dict(re.findall(r'^      (\S+): (.+)$', block, re.M))


ABBR = _book_abbrs()

# страница автора (path, title) — на неё вешаются пункты меню трудов
AUTHOR = ('Kd1A_クアドラトゥス1世紀2世紀', 'クアドラトゥス、1–2世紀')

# греческий оригинал, где сохранился единственный фрагмент Кодрата (наш 底本)
GRC_HE4 = 'https://bibleox.com/ja/grc/w/ΕΚΚΛΗΣΙΑΣΤΙΚΗΣ_ΙΣΤΟΡΙΑΣ-4'


def b(book, ch, vs, label=None):
    """Ссылка на стих в jp-ni: b('2tim', 2, 15) -> ２テモ. 2:15"""
    label = label or f"{ABBR[book]}. {ch}:{vs}"
    return f'<a href="https://bibleox.com/ja/jp-ni/{book}/{ch}/#L{vs}">{label}</a>'


def check_links(body, refs=''):
    """Грубые проверки парности тегов и согласованности внутренних ссылок"""
    for tag in ('p', 'strong', 'em', 'mark', 'u', 'blockquote', 'h2', 'h3', 'ol', 'li'):
        opens = len(re.findall(f'<{tag}[ >]', body)) + len(re.findall(f'<{tag}[ >]', refs))
        closes = len(re.findall(f'</{tag}>', body)) + len(re.findall(f'</{tag}>', refs))
        assert opens == closes, (tag, opens, closes)
    # якоря #HH-... ведут только на реально существующие заголовки этого же документа
    heads = set(re.findall(r'<h[23]>([^<]+)</h[23]>', body))
    def anchor_of(h):
        t = re.sub(r'<[^>]+>', '', h)
        t = re.sub(r'[^\w\s\-]', '', t, flags=re.UNICODE)
        return 'HH-' + t.strip().replace(' ', '-')
    anchors = {anchor_of(h) for h in heads}
    for href in re.findall(r'href="#(HH-[^"]+)"', body):
        assert href in anchors, f'внутренний якорь не найден: {href} из {anchors}'
    # сноски: [n] в тексте ровно 1..N, в примечаниях N пунктов
    nums = [int(n) for n in re.findall(r'\[(\d+)\]', body)]
    assert nums == sorted(set(nums)) and nums == list(range(1, len(nums) + 1)), nums
    n_items = len(re.findall(r'<li>', refs))
    assert n_items == len(nums), (n_items, len(nums))
    # кириллица в ja-тексте запрещена (кроме бренда «Библeокс», здесь его нет)
    cyr = re.findall(r'[\u0400-\u04FF]', body + refs)
    assert not cyr, f'кириллица: {cyr[:20]}'


def build(src, path, title, title_sub, meta_desc, menu, body, refs, out_name, update=False, builder=None):
    """Пишет db/translations/ja/<out_name>.yml"""
    check_links(body, refs)
    lines = [
        f"# Кодрат, «{src}»: японский перевод. Собирается из tmp/ja_fathers/quadratus/{builder}",
        f"# Загрузка: bin/rails pages:import_translations FILE=db/translations/ja/{out_name} [PUBLISH=1] [DRY_RUN=1]",
        "lang: ja",
        "list: chirch_writers_jp",
    ]
    lines.append("pages:")
    lines += [
        f"  - src: {src}",
        f"    path: {path}",
        f"    title: {title}",
    ]
    if title_sub:
        lines.append(f"    title_sub: {title_sub}")
    lines += [
        f"    meta_desc: {meta_desc}",
        f"    menu: {{ parent: \"{menu['parent']}\", title: \"{menu['title']}\", priority: {menu['priority']}"
        + (f", replace: \"{menu['replace']}\" }}" if menu.get('replace') else " }"),
    ]
    if menu.get('copy_cover'):
        lines.append("    copy_cover: true")
    if update:
        lines.append("    update: true")
    lines.append("    body: |-")
    lines += [("      " + l) for l in body.split('\n')]
    if refs:
        lines.append("    references: |-")
        lines += [("      " + l) for l in refs.split('\n')]
    os.makedirs(os.path.join(os.path.dirname(__file__), '..', '..', '..', 'db/translations/ja'), exist_ok=True)
    out = os.path.join(os.path.dirname(__file__), '..', '..', '..', 'db/translations/ja', out_name)
    open(out, 'w').write('\n'.join(lines) + '\n')
    print(f'{out_name}: body {len(body)}, refs {len(refs)}')
