#!/usr/bin/env python3
# Общие помощники для китайских (zh-Hans) переводов посланий Игнатия (tmp/ign/zh_*.py)
import os
import re

ROOT = os.path.join(os.path.dirname(__file__), '..', '..')


def _book_abbrs():
    """Короткие названия книг из config/locales/zh-Hans.yml (books.short, по 思高)"""
    text = open(os.path.join(ROOT, 'config/locales/zh-Hans.yml')).read()
    block = text.split('\n  books:\n    short:\n', 1)[1].split('\n    mid:', 1)[0]
    return dict(re.findall(r'^      (\S+): (.+)$', block, re.M))


ABBR = _book_abbrs()
EP = {'E': ('Ig4E_致以弗所人书', '致以弗所人书'),
      'M': ('Ig4M_致马格尼西亚人书', '致马格尼西亚人书'),
      'T': ('Ig4T_致特拉勒斯人书', '致特拉勒斯人书'),
      'R': ('Ig4R_致罗马人书', '致罗马人书'),
      'F': ('Ig4F_致非拉铁非人书', '致非拉铁非人书'),
      'S': ('Ig4S_致士每拿人书', '致士每拿人书'),
      'P': ('Ig4P_致坡旅甲书', '致坡旅甲书')}

# страница автора, в меню которой добавляются послания
LIST = 'Ig4A_安提阿的伊格那丢一世纪'


def b(book, ch, vs, label=None):
    """Ссылка на стих в cn-sb: b('ef', 1, '4-5') -> 弗 1:4-5"""
    label = label or f"{ABBR[book]} {ch}:{vs}"
    return f'<a href="https://bibleox.com/zh-Hans/cn-sb/{book}/{ch}/#L{vs}">{label}</a>'


def i(ep, ch, sec=None):
    """Ссылка на главу послания Игнатия: i('M', 3, '1-2') -> 《致马格尼西亚人书》3:1-2"""
    path, title = EP[ep]
    ref = f"{ch}:{sec}" if sec else f"第{ch}章"
    return f'<a href="https://bibleox.com/zh-Hans/zh-Hans/w/{path}#HH-{ch}">《{title}》{ref}</a>'


def here(ch, sec=None):
    """Ссылка на главу этого же послания"""
    ref = f"{ch}:{sec}" if sec else f"第{ch}章"
    return f'<a href="#HH-{ch}">{ref}</a>'


def build(key, src, file_num, slug, ch_paras, notes, meta_desc, menu_priority, source_grc_path):
    """Проверяет сноски и пишет db/translations/zh-Hans/ign_{file_num}_{slug}.yml"""
    body_all = ''.join(''.join(v) for v in ch_paras.values())
    nums = [int(n) for n in re.findall(r'\[(\d+)\]', body_all)]
    assert nums == list(range(1, len(notes) + 1)), (nums, len(notes))
    path, title = EP[key]
    source = ("翻译：罗季翁·弗拉索夫（借助人工智能工具）。底本：希腊文原文"
              f'（<a href="https://bibleox.com/zh-Hans/grc/w/{source_grc_path}">本站的希腊文版本</a>，明显的脱漏据莱特福特本和霍姆斯本补足）。'
              "参考：俄文译本（《早期教父文选》，布鲁塞尔，1988年）、英文译本（Roberts–Donaldson）、法文译本（Genoude，1837年）。"
              "圣经链接指向本站的思高本。")
    body = '\n'.join(f"<h2>{ch}</h2>" + ''.join(f"<p>{p}</p>" for p in paras) for ch, paras in ch_paras.items())
    refs = '<ol>' + ''.join(f"<li><p>{n}</p></li>" for n in notes) + '</ol>\n<p>' + source + '</p>'
    os.makedirs(os.path.join(ROOT, 'db/translations/zh-Hans'), exist_ok=True)
    out = [
        f"# Игнатий Богоносец, «{src}»: китайский перевод с греческого. Собирается из tmp/ign/zh_{slug}.py",
        f"# Загрузка: bin/rails pages:import_translations FILE=db/translations/zh-Hans/ign_{file_num}_{slug}.yml [PUBLISH=1] [DRY_RUN=1]",
        "lang: zh-Hans",
        f"list: {LIST}",
        "folders:",
        '  - { path: "书信", priority: 1 }',
        "pages:",
        f"  - src: {src}",
        f"    path: {path}",
        f"    title: {title}",
        f"    meta_desc: {meta_desc}",
        f'    menu: {{ parent: "书信", title: "{title}", priority: {menu_priority} }}',
        "    body: |-",
        *("      " + l for l in body.split('\n')),
        "    references: |-",
        *("      " + l for l in refs.split('\n')),
    ]
    open(os.path.join(ROOT, f'db/translations/zh-Hans/ign_{file_num}_{slug}.yml'), 'w').write('\n'.join(out) + '\n')
    print(f'{slug}: chapters {len(ch_paras)}, notes {len(notes)}')
