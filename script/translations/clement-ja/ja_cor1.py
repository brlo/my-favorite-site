#!/usr/bin/env python3
# «К Коринфянам I» (ru 419, grc 429) -> db/translations/ja/kl_01_cor1.yml
# Сборка из частей ja_cor1_a.py (INFO + 0-21), ja_cor1_b.py (22-46), ja_cor1_c.py (47-65).
# Проверки: паритет структуры с греческим оригиналом (гл/абзацы), вхождение цитат
# авторской страницы (ja_author.QUOTES), нумерация сносок [1]..[N].
import sys, os, json, re
sys.path.insert(0, os.path.dirname(__file__))
from ja_common import *
from ja_cor1_a import CH_A, NOTES_A, INFO
from ja_cor1_b import CH_B, NOTES_B
from ja_cor1_c import CH_C, NOTES_C

CH = {}
CH.update(CH_A); CH.update(CH_B); CH.update(CH_C)
NOTES = NOTES_A + NOTES_B + NOTES_C

# --- 1. Паритет структуры с греческим оригиналом ---
grc = json.load(open(os.path.join(os.path.dirname(__file__), 'grc_cor1_structure.json')))
gch = grc['chapters']
# главы 1..57 кроме 57 (в ja 57 = 6 + восстановленный 57:7), 64, 65 — точный паритет
for ch, paras in gch.items():
    if ch.isdigit() and int(ch) >= 1 and int(ch) <= 65 and ch != '57':
        assert len(CH[ch]) == len(paras), f'глава {ch}: ja {len(CH[ch])} paras vs grc {len(paras)}'
assert len(CH['57']) == 7, len(CH['57'])  # 6 (Александринский) + 57:7 (восстановленный)
# приложение = 57:7 + гл. 58-63 (21 абзац)
app = gch['Παράρτημα (57-63)']
assert len(app) == 21
n_rest = len(app) - 1  # без 57:7
ja_rest = sum(len(CH[c]) for c in ('58', '59', '60', '61', '62', '63'))
assert ja_rest == n_rest, (ja_rest, n_rest)
assert len(CH['0']) == 1 and len(CH['64']) == 1 and len(CH['65']) == 2

# --- 2. Цитаты авторской страницы обязаны входить дословно ---
from ja_author import QUOTES
for ch, frag in QUOTES:
    paras = [re.sub(r'\[\d+\]', '', re.sub(r'^\d+\. ', '', p)) for p in CH[ch]]  # номера абзацев и маркеры сносок снимаются
    joined = ''.join(paras)
    assert frag in joined, f'цитата не входит в главу {ch}: {frag[:60]}...'

# --- 3. Сноски: автоперенумерация по порядку следования в тексте ---
counter = 0
def renum(m):
    global counter
    counter += 1
    return f'[{counter}]'
for ch in sorted(CH, key=lambda c: int(c) if c.isdigit() else 999):
    CH[ch] = [re.sub(r'\[\d+\]', renum, p) for p in CH[ch]]
assert counter == len(NOTES), (counter, len(NOTES))

# --- 4. Сборка тела ---
info_html = '<h2>二つの書簡について</h2>' + ''.join(f'<p>{p}</p>' for p in INFO)
body = info_html + chapter_body(CH)

refs = '<ol>' + ''.join(f'<li><p>{n}</p></li>' for n in NOTES) + '</ol>'
refs += ('<p>翻訳：ロジオン・ヴラソフ（AIツールを併用）。底本：ギリシア語本文'
         f'（<a href="https://bibleox.com/ja/grc/w/ΚλΡμ_Κορ1">本サイトのギリシア語版</a>）。'
         '参照：ロシア語訳（プレオブラジェンスキー訳。第57:7節と第58–63章はプリシェルコフ訳による）、'
         '英訳（Roberts–Donaldson）。第57:7節と第58–63章はアレクサンドリア写本に欠けており、'
         '1056年製作のエルサレム駐在所写本（Codex Hierosol. 54）によって補い、'
         'ここでは原書の章節の順に従って本文に組み入れた。聖書のリンクは本サイトの新共同訳を指す。'
         '翻訳原則：作者が聖書を引用する箇所は、彼自身が用いたテキスト（おおむね七十人訳）の語句に従って訳し、'
         '新共同訳と措辞が異なる箇所は注で示して新共同訳へのリンクを付した；'
         '用語・人名はイグナティオス書簡の日本語訳（本サイト）に倣う；'
         '段落番号はギリシア語原文の章・節の区分による（章:節 で引用できる）。</p>')

build(
    src='КлРим_Кор1',
    path='Kl1C1_コリントの教会への手紙第一',
    title='コリントの教会への手紙 第一',
    title_sub=None,
    meta_desc='ローマの主教クレメンスがコリントの教会に宛てた書簡（96〜97年頃）：教会内の分裂と叛乱を戒めて和解を勧め、使徒時代の信仰と教会の秩序を証しする。ギリシア語原文からの翻訳と注。',
    menu={'parent': '手紙', 'title': 'コリントの教会への手紙 第一', 'priority': 1,
          'folders': [('手紙', 1)], 'copy_cover': True},
    body=body,
    refs=refs,
    out_name='kl_01_cor1.yml',
    is_list_author=True,
    builder='ja_cor1.py',
    update=True,
)
