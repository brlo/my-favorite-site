#!/usr/bin/env python3
# Общие помощники для японских переводов посланий Игнатия (tmp/ign/ja_*.py)
import json

ABBR = {'gal': 'ガラ', 'kol': 'コロ', 'fil': 'フィリ', 'evr': 'ヘブ', 'is': 'イザ', '2kor': '２コリ', 'lk': 'ルカ', 'otkr': '黙', 'tit': 'テト', 'gen': '創', '1sol': '１テサ', '2sol': '２テサ', 'iez': 'エゼ', 'ier': 'エレ', 'os': 'ホセ', 'mal': 'マラ', 'pp': '雅', 'ekl': 'コヘ', 'iov': 'ヨブ', 'vtor': '申', 'ish': '出', 'lev': 'レビ', 'zah': 'ゼカ', '1ts': 'サム上',
        'ef': 'エフェ', 'act': '使', 'fm': 'フィレ', 'in': 'ヨハ', 'mf': 'マタ', 'mk': 'マコ', 'pr': '箴',
        'iak': 'ヤコ', '1pet': '１ペト', '1kor': '１コリ', '2tim': '２テモ', '1tim': '１テモ', 'rim': 'ロマ',
        'ps': '詩', '1in': '１ヨハ'}
EP = {'E': ('Ig1E_エフェソの教会への手紙', 'エフェソの教会への手紙'),
      'M': ('Ig1M_マグネシアの教会への手紙', 'マグネシアの教会への手紙'),
      'T': ('Ig1T_トラレスの教会への手紙', 'トラレスの教会への手紙'),
      'R': ('Ig1R_ローマの教会への手紙', 'ローマの教会への手紙'),
      'F': ('Ig1F_フィラデルフィアの教会への手紙', 'フィラデルフィアの教会への手紙'),
      'S': ('Ig1S_スミルナの教会への手紙', 'スミルナの教会への手紙'),
      'P': ('Ig1P_ポリュカルポスへの手紙', 'ポリュカルポスへの手紙')}


def b(book, ch, vs, label=None):
    """Ссылка на стих в jp-ni: b('ef', 1, '4-5')"""
    label = label or f"{ABBR[book]}. {ch}:{vs}"
    return f'<a href="https://bibleox.com/ja/jp-ni/{book}/{ch}/#L{vs}">{label}</a>'


def i(ep, ch, sec=None):
    """Ссылка на главу послания Игнатия: i('M', 3, '1-2') -> 『マグネシアの教会への手紙』3:1-2"""
    path, title = EP[ep]
    ref = f"{ch}:{sec}" if sec else f"{ch}章"
    return f'<a href="https://bibleox.com/ja/ja/w/{path}#HH-{ch}">『{title}』{ref}</a>'


def here(ch, sec=None):
    """Ссылка на главу этого же послания"""
    ref = f"{ch}:{sec}" if sec else f"{ch}章"
    return f'<a href="#HH-{ch}">{ref}</a>'

# страница автора, в меню которой добавляются послания
LIST = 'mlNq_アンティオキアのイグナティオス1世紀'


def build(key, src, file_num, slug, ch_paras, notes, meta_desc, menu_priority, source_grc_path):
    """Проверяет сноски и пишет db/translations/ja/ign_{file_num}_{slug}.yml"""
    import re
    body_all = ''.join(''.join(v) for v in ch_paras.values())
    nums = [int(n) for n in re.findall(r'\[(\d+)\]', body_all)]
    assert nums == list(range(1, len(notes) + 1)), (nums, len(notes))
    path, title = EP[key]
    source = ("翻訳：ロジオン・ヴラソフ（AIツールを併用）。底本：ギリシア語本文"
              f'（<a href="https://bibleox.com/ja/grc/w/{source_grc_path}">本サイトのギリシア語版</a>。明らかな脱落はライトフット版・ホームズ版で補った）。'
              "参照：ロシア語訳（『初期教会教父選集』ブリュッセル、1988年）、英訳（Roberts–Donaldson）、仏訳（Genoude、1837年）。"
              "聖書の引用は新共同訳による。")
    body = '\n'.join(f"<h2>{ch}</h2>" + ''.join(f"<p>{p}</p>" for p in paras) for ch, paras in ch_paras.items())
    refs = '<ol>' + ''.join(f"<li><p>{n}</p></li>" for n in notes) + '</ol>\n<p>' + source + '</p>'
    out = [
        f"# Игнатий Богоносец, «{src}»: японский перевод с греческого. Собирается из tmp/ign/ja_{slug}.py",
        f"# Загрузка: bin/rails pages:import_translations FILE=db/translations/ja/ign_{file_num}_{slug}.yml [PUBLISH=1] [DRY_RUN=1]",
        "lang: ja",
        f"list: {LIST}",
        "pages:",
        f"  - src: {src}",
        f"    path: {path}",
        f"    title: {title}",
        f"    meta_desc: {meta_desc}",
        f'    menu: {{ parent: "手紙", title: "{title}", priority: {menu_priority} }}',
        "    body: |-",
        *("      " + l for l in body.split('\n')),
        "    references: |-",
        *("      " + l for l in refs.split('\n')),
    ]
    open(f'db/translations/ja/ign_{file_num}_{slug}.yml', 'w').write('\n'.join(out) + '\n')
    print(f'{slug}: chapters {len(ch_paras)}, notes {len(notes)}')
