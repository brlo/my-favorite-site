#!/usr/bin/env python3
# Сборка ja-переводов трудов Иустина из драфт-батчей (draft/a1_batch*.py и т.д.)
# -> db/translations/ja/ju_*.yml
# Пайплайн: драфт-агенты (CH/TITLES/NOTES) -> паритет абзацев с ru -> плейсхолдеры
# {{B:book ch:vs}} -> <a> ссылки на jp-ni (псалом LXX->jp-ni, отчёт для ручной сверки),
# {{N:id}} -> автонумерация [n] + <ol> в references. Кириллица запрещена.
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'quadratus'))
from ja_common import ABBR  # те же book.short из config/locales/ja.yml

# ---------------------------------------------------------------- конфиг работ
WORKS = {
    'a1': dict(
        src='Иустин_Философ-Апология_1',
        path='Ju2C1_弁明書第一',
        title='弁明書 第一',
        title_sub='ローマ皇帝に献げられた',
        meta_desc='2世紀のキリスト教護教家ユスティノス（哲学者）がローマ皇帝アントニヌス・ピウスに献げた弁明書（第一）：キリスト教の信仰と実践を擁護し、哲学と預言者の証しをもって示す。ギリシア語原文（マルコヴィッチ校訂版の章立て）からの翻訳と注。',
        batches=['a1_batchA', 'a1_batchB', 'a1_batchC', 'a1_batchD', 'a1_batchE'],
        ru_dir='src/a1/ru',
        menu_priority=1,
        out='ju_01_a1.yml',
    ),
    'a2': dict(
        src='Иустин_Философ-Апология_2',
        path='Ju2C2_弁明書第二',
        title='弁明書 第二',
        title_sub='ローマ元老院に献げられた',
        meta_desc='ユスティノス（哲学者）がローマ元老院に献げた弁明書（第二）：キリスト者が死刑に処されることの不当を、真の善と悪に基づいて示す。ギリシア語原文からの翻訳と注。',
        batches=['a2_batchA'],
        ru_dir='src/a2/ru',
        menu_priority=2,
        out='ju_02_a2.yml',
    ),
    'dialog': dict(
        src='Иустин_Философ-разговор_с_Трифоном_иудеем',
        path='Ju2D_ユダヤ人トリュフォンとの対話',
        title='ユダヤ人トリュフォンとの対話',
        title_sub=None,
        meta_desc='ユスティノス（哲学者）とユダヤ人トリュフォンとの対話（エフェソ、135年頃）：旧約聖書の預言からキリストと新しい契約を示し、律法と割礼と安息日の意味を論じる。ギリシア語原文からの翻訳と注。',
        batches=[],  # dialog_batchA..H — заполняется при сборке
        ru_dir='src/dialog/ru',
        menu_priority=3,
        out='ju_03_dialog.yml',
    ),
}

# ------------------------------------------------------------- плейсхолдеры
BPL = re.compile(r'\{\{B:([^}]+)\}\}')
NPL = re.compile(r'\{\{N:(\w+)\}\}')

BOOKS_NT = set('mf mk lk in act rim 1kor 2kor gal ef fil kol 1sol 2sol 1tim 2tim tit fm evr iak 1pet 2pet 1in 2in 3in iud otkr'.split())
BOOKS_OT = set('gen ish lev chis vtor nav sud ruf 1ts 2ts 3ts 4ts 1par 2par ezd neem esf iov ps pr ekl pp prs prsir is ier pier pos iez dan os iol am ion mih naum av sof ag zah mal tov iudf 1mak 2mak var 2ezd 3ezd'.split())
ALL_BOOKS = BOOKS_NT | BOOKS_OT

REF = re.compile(r'([a-z0-9]+)\s+(\d+):(\d+)(?:-(\d+))?')


def parse_ref(spec):
    """'is 66:1; ps 96:10' -> [(book, ch, vs1, vs2|None), ...]"""
    out = []
    for part in spec.split(';'):
        part = part.strip()
        m = REF.fullmatch(part)
        if not m:
            raise ValueError(f'bad ref: {part!r}')
        book, ch, vs1, vs2 = m.group(1), int(m.group(2)), int(m.group(3)), m.group(4)
        if book not in ALL_BOOKS:
            raise ValueError(f'unknown book code: {book}')
        out.append((book, ch, vs1, int(vs2) if vs2 else None))
    return out


def ps_lxx_to_jpni(n):
    """Псалом ru (LXX) -> jp-ni (еврейская нумерация). Пс 50 -> 詩51 (прецедент).
    Простое смещение +1 для LXX 10..113; композитные (114/115, 146/147) — вручную."""
    if n >= 10 and n <= 113:
        return n + 1
    if n in (114, 115):
        return 116  # обе = Пс 116 евр.
    if n == 116:
        return 117
    if n == 117:
        return 118
    return n  # 1..9 и 146..150 — сверять вручную


def jpni_verses(refs):
    """[(book, ch, vs1, vs2|None)] -> {address: text}; адреса в jp-ni нумерации."""
    addrs = []
    for book, ch, vs1, vs2 in refs:
        n = ch
        if book == 'ps':
            n = ps_lxx_to_jpni(ch)
        vs_last = vs2 if vs2 else vs1
        if vs_last - vs1 > 40:
            raise ValueError(f'range too long: {book} {ch}:{vs1}-{vs_last}')
        for v in range(vs1, vs_last + 1):
            addrs.append(f'{book}:{n}:{v}')
    addrs = sorted(set(addrs))
    if not addrs:
        return {}
    sql = ("SELECT address, text FROM verses WHERE tr_code='jp-ni' AND address IN (" +
           ','.join(f"'{a}'" for a in addrs) + ')')
    out = subprocess.run(['docker', 'exec', 'bibpostgres', 'psql', '-U', 'bibleox',
                          'bibleox_development', '-t', '-A', '-F', '\x1f', '-c', sql],
                         capture_output=True, text=True, check=True).stdout
    res = {}
    for line in out.strip().split('\n'):
        if not line:
            continue
        addr, text = line.split('\x1f', 1)
        res[addr] = text
    return res


def link(book, ch, vs1, vs2, jpni_ch=None):
    n = jpni_ch if jpni_ch is not None else ch
    last = vs2 if vs2 else vs1
    label = f"{ABBR[book]}. {n}:{vs1}" + (f"-{last}" if vs2 else '')
    return f'<a href="https://bibleox.com/ja/jp-ni/{book}/{n}/#L{vs1}">{label}</a>'


def expand_body(text, verses):
    """{{B:...}} -> （links）; {{N:id}} оставляем (перенумерация отдельно)."""
    def sub_b(m):
        refs = parse_ref(m.group(1))
        for book, ch, vs1, vs2 in refs:
            n = ch if book != 'ps' else ps_lxx_to_jpni(ch)
            key = f'{book}:{n}:{vs1}'
            if key not in verses and vs1 != 0:
                raise AssertionError(f'стих не найден в jp-ni: {book} {ch}:{vs1} (jp-ni {n})')
        parts = []
        for book, ch, vs1, vs2 in refs:
            n = ch if book != 'ps' else ps_lxx_to_jpni(ch)
            parts.append(link(book, ch, vs1, vs2, jpni_ch=n))
        return '（' + '、'.join(parts) + '）'
    return BPL.sub(sub_b, text)


# ------------------------------------------------------------- загрузка драфтов
def load_draft(name):
    ns = {'__file__': os.path.join(HERE, 'draft', name + '.py')}
    exec(open(os.path.join(HERE, 'draft', name + '.py'), encoding='utf-8').read(), ns)
    return ns['CH'], ns.get('TITLES', {}), ns['NOTES'], ns.get('REPORT', '')


def ru_chapters(ru_dir):
    """{num: (title, [абзацы])} из файлов chNN.txt; ключ — номер из H2 (для
    прескрипта Диалога ch01 с нечисловым заголовком ключ 0)."""
    out = {}
    for fn in sorted(os.listdir(os.path.join(HERE, ru_dir))):
        m = re.fullmatch(r'ch(\d+)\.txt', fn)
        if not m:
            continue
        raw = open(os.path.join(HERE, ru_dir, fn), encoding='utf-8').read()
        title = raw.split('\n', 1)[0][4:].strip()
        body = raw.split('\n', 1)[1]
        paras = [p.strip() for p in re.split(r'\n\s*\n', body) if p.strip()]
        file_num = int(m.group(1))
        dm = re.match(r'(\d+)\s*—\s*(.*)', title)
        if title.isdigit():
            key = int(title)
        elif dm:
            key = int(dm.group(1))
        else:
            key = 0 if file_num == 1 else file_num
        out[key] = (title, paras)
    return out


def check_no_cyrillic(s):
    cyr = re.findall(r'[\u0400-\u04FF]', s)
    if cyr:
        raise AssertionError(f'кириллица: {cyr[:30]}')


def build_work(key, draft_names=None):
    w = WORKS[key]
    drafts = draft_names if draft_names is not None else w['batches']
    if not drafts:
        raise SystemExit(f'{key}: не заданы драфт-файлы')
    ru = ru_chapters(w['ru_dir'])
    CH, TITLES, NOTES, reports = {}, {}, [], []
    for name in drafts:
        ch, titles, notes, rep = load_draft(name)
        for n, paras in ch.items():
            if n in CH:
                raise SystemExit(f'{key}: глава {n} в двух батчах')
            CH[n] = paras
        TITLES.update(titles)
        NOTES += notes
        reports.append(f'{name}: {rep}')
    # --- паритет глав и абзацев
    missing = set(ru) - set(CH)
    extra = set(CH) - set(ru)
    if missing or extra:
        raise SystemExit(f'{key}: главы не совпадают с ru; нет={sorted(missing)} лишние={sorted(extra)}')
    for n, (title, paras) in sorted(ru.items()):
        if len(CH[n]) != len(paras):
            raise SystemExit(f'{key}: гл.{n} абзацев ja={len(CH[n])} ru={len(paras)}')
    # --- сбор ссылок и сносок
    all_refs = {}
    ref_ctx = {}  # (book,ch,vs1,vs2) -> ja-контекст перед плейсхолдером (для ручной сверки)
    note_ids = {}
    order = []
    body_parts = []
    for n in sorted(CH):
        title = TITLES.get(n) if TITLES.get(n) else ru[n][0]
        # числовые главы — номер как есть; именные — ja-заголовок (без номера, если номер в нём уже есть)
        if title.isdigit():
            h2 = title
        elif re.fullmatch(r'\d+ — .*', title):
            h2 = title
        elif n == 0:
            h2 = title  # вводная глава (прескрипт) — без номера
        else:
            h2 = f'{n} — {title}'
        paras = []
        for p in CH[n]:
            for m in BPL.finditer(p):
                for r in parse_ref(m.group(1)):
                    all_refs[r] = True
                    if r not in ref_ctx:
                        ref_ctx[r] = p[max(0, m.start() - 45):m.start()]
            for m in NPL.finditer(p):
                nid = m.group(1)
                if nid not in note_ids:
                    note_ids[nid] = len(order) + 1
                    order.append(nid)
            paras.append(p)
        body_parts.append((n, h2, paras))
    # --- резолвер стихов (ссылки есть и в примечаниях!)
    for nid, t in NOTES:
        for m in BPL.finditer(t):
            for r in parse_ref(m.group(1)):
                all_refs[r] = True
    verse_texts = jpni_verses(list(all_refs))
    ps_report = sorted({k for k in all_refs if k[0] == 'ps'}, key=lambda r: (r[1], r[2], r[3] or 0))
    # --- развёртка body
    html = []
    for n, h2, paras in body_parts:
        html.append(f'<h2>{h2}</h2>')
        for p in paras:
            p = expand_body(p, verse_texts)
            p = NPL.sub(lambda m: f'[{note_ids[m.group(1)]}]', p)
            html.append(f'<p>{p}</p>')
    body = ''.join(html)
    # --- сноски (в порядке появления)
    notes_by_id = dict((str(i), t) for i, t in NOTES)
    loose = set(notes_by_id) ^ set(order)
    if loose:
        raise SystemExit(f'{key}: маркеры сносок и NOTES не совпали: {sorted(loose)}')
    ol_items = []
    for nid in order:
        t = notes_by_id[nid]
        t = expand_body(t, verse_texts)
        ol_items.append(f'<li><p>{t}</p></li>')
    refs = '<ol>' + ''.join(ol_items) + '</ol>'
    # --- принципы
    refs += (
        '<p>翻訳：ロジオン・ヴラソフ（AIツールを併用）。底本：ギリシア語原文'
        '（M. マルコヴィッチ校訂版による章立て；この作品は本サイトにギリシア語原文ページがなく、'
        '外部の校訂版に従います）。訳出にあたっては本サイトのロシア語版と英語版（ANF）を参照しました。'
        '聖書の引用はユスティノス自身の用いた語句（おおむね七十人訳）に従って訳し、'
        '新共同訳と異なる箇所は注で説明します。引用箇所のリンクは新共同訳の当該箇所を指します。</p>'
    )
    # --- проверки
    check_no_cyrillic(body + refs)
    for tag in ('h2', 'p', 'ol', 'li', 'a'):
        o = len(re.findall(f'<{tag}[ >]', body)) + len(re.findall(f'<{tag}[ >]', refs))
        c = len(re.findall(f'</{tag}>', body)) + len(re.findall(f'</{tag}>', refs))
        assert o == c, (key, tag, o, c)
    assert f'{{{{B:' not in body and f'{{{{N:' not in body, f'{key}: остались плейсхолдеры'
    for tag in ('strong', 'em', 'blockquote'):
        assert f'<{tag}' not in body, f'{key}: неожиданный <{tag}>'
    # --- YAML
    lines = [
        f"# ユスティノス「{w['title']}」: японский перевод. Собирается из tmp/ja_fathers/justin/build_work.py",
        f"# Загрузка: bin/rails pages:import_translations FILE=db/translations/ja/{w['out']} [PUBLISH=1] [DRY_RUN=1]",
        'lang: ja',
        "list: Ju2A_ユスティノス2世紀",
        'folders:',
        '  - { path: "著作", priority: 1 }',
        'pages:',
        f"  - src: {w['src']}",
        f"    path: {w['path']}",
        f"    title: {w['title']}",
    ]
    if w['title_sub']:
        lines.append(f"    title_sub: {w['title_sub']}")
    lines += [
        f"    meta_desc: {w['meta_desc']}",
        f"    menu: {{ parent: \"著作\", title: \"{w['title']}\", priority: {w['menu_priority']} }}",
        '    update: true',
        '    body: |-',
    ]
    lines += [('      ' + l) for l in body.split('\n')]
    lines.append('    references: |-')
    lines += [('      ' + l) for l in refs.split('\n')]
    out = os.path.join(HERE, '..', '..', '..', 'db/translations/ja', w['out'])
    open(out, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    # --- отчёты
    n_b = len(BPL.findall(body))
    print(f"== {w['out']}: глав {len(CH)}, абзацев {sum(len(p) for _,_,p in body_parts)}, сносок {len(order)}, ссылок Б {n_b}")
    for r in reports:
        print('   REPORT', r)
    if ps_report:
        print('   ПСАЛТИРЬ (ru LXX -> jp-ni), сверить по текстам:')
        for book, ch, vs1, vs2 in ps_report:
            n = ps_lxx_to_jpni(ch)
            print(f'     Пс{ch}:{vs1} -> ps:{n}:{vs1}: {verse_texts.get(f"ps:{n}:{vs1}", "(нет)")[:60]}')
    print('   СВЕРКА ССЫЛОК (ja-контекст -> стих jp-ni):')
    for (book, ch, vs1, vs2), ctx in sorted(ref_ctx.items(), key=lambda x: (x[0][0], x[0][1], x[0][2])):
        n = ps_lxx_to_jpni(ch) if book == 'ps' else ch
        txt = verse_texts.get(f'{book}:{n}:{vs1}', '(НЕТ СТИХА!)')
        print(f'     {book} {ch}:{vs1}-{vs2 or vs1} | ja: …{ctx[-40:]} | jp-ni: {txt[:55]}')
    return body, refs


if __name__ == '__main__':
    key = sys.argv[1]
    drafts = sys.argv[2:] or None
    build_work(key, drafts)
