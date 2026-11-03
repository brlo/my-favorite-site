#!/usr/bin/env python3
# Общие помощники для японского перевода трудов Поликарпа Смирнского (script/translations/pol/pol_*.py)
import os, re, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'ign'))
from ja_common import ABBR, b, i  # ссылки на jp-ni и на японские послания Игнатия

ABBR.update({'tov': 'トビ', 'nav': 'ヨシュ', 'iud': 'ユダ', '2in': '２ヨハ', 'mk': 'マコ', 'dan': 'ダニ',
             'chis': '民', '4ts': '王下', '2pet': '２ペト', 'is': 'イザ', 'iez': 'エゼ'})

AUTHOR = ('Pk1A_スミルナのポリュカルポス1世紀2世紀', 'スミルナのポリュカルポス')
PHIL = ('Pk1F_フィリピの教会への手紙', 'フィリピの教会への手紙')
MART = ('Pk1M_ポリュカルポスの殉教', 'ポリュカルポスの殉教')
IGN = 'mlNq_アンティオキアのイグナティオス1世紀'


def w(work, ch, sec=None, label=None):
    """Ссылка на главу труда: w(MART, 9, 3) -> 『ポリュカルポスの殉教』9:3"""
    path, title = work
    ref = f"{ch}:{sec}" if sec else f"{ch}章"
    return f'<a href="https://bibleox.com/ja/ja/w/{path}#HH-{ch}">{label or f"『{title}』{ref}"}</a>'


def here(ch, sec=None):
    ref = f"{ch}:{sec}" if sec else f"{ch}章"
    return f'<a href="#HH-{ch}">{ref}</a>'


def number_notes(ch_paras, notes):
    """Сноски в тексте пишутся как [#] и нумеруются по порядку"""
    n = 0

    def repl(_):
        nonlocal n
        n += 1
        return f'[{n}]'
    out = {ch: [re.sub(r'\[#\]', repl, p) for p in paras] for ch, paras in ch_paras.items()}
    assert n == len(notes), (n, len(notes))
    return out


def body_html(ch_paras):
    return '\n'.join(f"<h2>{ch}</h2>" + ''.join(f"<p>{p}</p>" for p in paras) for ch, paras in ch_paras.items())


def refs_html(notes, source):
    return '<ol>' + ''.join(f"<li><p>{n}</p></li>" for n in notes) + '</ol>\n<p>' + source + '</p>'


def write_yaml(file, header, pages, list_path=IGN, folders=None):
    """pages: [{src, path, title, title_sub, meta_desc, menu, body, references, copy_cover}]"""
    out = [*('# ' + h for h in header), "lang: ja", f"list: {list_path}"]
    if folders:
        out.append("folders:")
        out += [f'  - {{ path: "{f}", priority: {p} }}' for f, p in folders]
    out.append("pages:")
    for pg in pages:
        out.append(f"  - src: {pg['src']}")
        for key in ('path', 'title', 'title_sub', 'meta_desc'):
            if pg.get(key):
                out.append(f"    {key}: {pg[key]}")
        if pg.get('update'):
            out.append("    update: true")
        if pg.get('copy_cover'):
            out.append("    copy_cover: true")
        if pg.get('menu'):
            out.append("    menu: { " + ', '.join(f'{k}: "{v}"' if isinstance(v, str) else f'{k}: {v}' for k, v in pg['menu'].items()) + " }")
        for key in ('body', 'references'):
            out.append(f"    {key}: |-")
            out += ["      " + l for l in pg[key].split('\n')]
    open(file, 'w').write('\n'.join(out) + '\n')

AUTHOR_LINK = f'<a href="https://bibleox.com/ja/ja/w/{AUTHOR[0]}#HH-生涯">本サイトのポリュカルポスのページ</a>'
IREN_LINK = '<a href="https://bibleox.com/ja/en/w/irenaeus-against-heresies-b3#HH-3">英語</a>'
MOSCOW_LINK = f'<a href="https://bibleox.com/ja/ja/w/{MART[0]}#HH-モスクワ写本による結び">『ポリュカルポスの殉教』モスクワ写本による結び</a>'
