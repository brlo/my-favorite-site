#!/usr/bin/env python3
# Общие помощники для японских (ja) переводов трудов Климента Римского
# (tmp/ja_fathers/clement/ja_*.py). По образцу polycarp-ja и zh-проекта:
# Библия — jp-ni (新共同訳), второканон тоже в jp-ni (トビ/知/シラ…); список
# авторской страницы — chirch_writers_jp (827), труды вешаются на Kl1A.
import os
import re


def _book_abbrs():
    """Короткие названия книг из config/locales/ja.yml (books.short)"""
    text = open(os.path.join(os.path.dirname(__file__), '..', '..', '..', 'config/locales/ja.yml')).read()
    block = text.split('\n  books:\n    short:\n', 1)[1].split('\n    mid:', 1)[0]
    return dict(re.findall(r'^      (\S+): (.+)$', block, re.M))


ABBR = _book_abbrs()

# страница автора (path, title) — на неё вешаются пункты меню трудов
AUTHOR = ('Kl1A_ローマのクレメンス1世紀', 'クレメンス（ローマの）、1世紀')

KL = {
    'C1': ('Kl1C1_コリントの教会への手紙第一', 'コリントの教会への手紙 第一'),
    'C2': ('Kl1C2_コリントの教会への手紙第二', 'コリントの教会への手紙 第二'),
}
# «О девстве» (Дев1/Дев2) в объём ja не входит — как решено для zh 18.11.


def b(book, ch, vs, label=None):
    """Ссылка на стих в jp-ni: b('rim', 12, 16) -> ロマ. 12:16"""
    label = label or f"{ABBR[book]}. {ch}:{vs}"
    return f'<a href="https://bibleox.com/ja/jp-ni/{book}/{ch}/#L{vs}">{label}</a>'


def bp(book, ch, label=None):
    """Ссылка на главу Библии без якоря стиха (ссылки вида «申. 16»)"""
    label = label or f"{ABBR[book]}. {ch}"
    return f'<a href="https://bibleox.com/ja/jp-ni/{book}/{ch}/">{label}</a>'


def w(ep, ch, sec=None):
    """Ссылка на главу труда Климента: w('C1', 44, '1-3') -> 『コリントの教会への手紙 第一』44:1-3"""
    path, title = KL[ep]
    ref = f"{ch}:{sec}" if sec else f"{ch}章"
    return f'<a href="https://bibleox.com/ja/ja/w/{path}#HH-{ch}">『{title}』{ref}</a>'


def here(ch, sec=None):
    """Ссылка на главу этого же труда"""
    ref = f"{ch}:{sec}" if sec else f"{ch}章"
    return f'<a href="#HH-{ch}">{ref}</a>'


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


def build(src, path, title, title_sub, meta_desc, menu, body, refs, out_name, is_list_author=False, update=False, builder=None):
    """Пишет db/translations/ja/<out_name>.yml"""
    check_links(body, refs)
    lines = [
        f"# Климент Римский, «{src}»: японский перевод. Собирается из tmp/ja_fathers/clement/{builder}",
        f"# Загрузка: bin/rails pages:import_translations FILE=db/translations/ja/{out_name} [PUBLISH=1] [DRY_RUN=1]",
        "lang: ja",
        f"list: {AUTHOR[0] if is_list_author else 'chirch_writers_jp'}",
    ]
    if menu.get('folders'):
        lines.append("folders:")
        lines += [f'  - {{ path: "{f}", priority: {p} }}' for f, p in menu['folders']]
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


def chapter_body(ch_paras, extra_h2=None):
    """{ch: [para,...]} -> html: <h2>ch</h2><p>..</p>..."""
    out = []
    for ch, paras in ch_paras.items():
        out.append(f"<h2>{ch}</h2>" + ''.join(f"<p>{p}</p>" for p in paras))
        if extra_h2 and ch in extra_h2:
            out.append(extra_h2[ch])
    return ''.join(out)
