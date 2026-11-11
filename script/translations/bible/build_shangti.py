#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Собирает 和合本 上帝版 1919 (классическая редакция) в двух графиках.

Исходники (ph4): CUVS — упрощённая, классическая редакция 1919 («串珠»,
сноски в <f>, форм 什么/作/希底结) и CUVt — традиционная со Стронгами,
редакция 1962-й линии (форм 甚麼/做/底格里斯, глоссы «（原文是…）» в тексте).
У CUVt сохранён типографский маркер 神版: U+3000 + 神 (в 上帝版 там 上帝).

Важно: CUVS и CUVt — РАЗНЫЕ редакции (5,8 тыс. стихов расходятся), поэтому
традиционный модуль строится не из CUVt, а конвертацией упрощённого, чтобы
обе графики совпадали слово в слово (иначе сверка фраз в q_build для zh-Hant
не сойдётся). CUVt используется только как источник позиций божественных 神.

Выход: cn-cuv.SQLite3 (упр.) и cn-cuvt.SQLite3 (трад.) + отчёт.

  1) cn-cuv: копия CUVS; позиции божественных 神 — сверка каждого стиха
     с CUVt (посимвольный t2s по OpenCC, только иероглифы и цифры, без
     пунктуации); расхождения изданий выравниваются difflib, 神 в
     неоднозначных зонах -> список на ручную проверку.
  2) cn-cuvt: те же тексты, конвертированные s2t (STPhrases + STCharacters
     OpenCC, теги не трогаются), с фиксированными заменами 着→著, 裡→裏;
     каждый стих сверяется обратным t2s; все неоднозначные иероглифы
     попадают в аудит-список.

Запуск (модули — скачанные данные, поэтому python3 -I):
  python3 -I script/translations/bible/build_shangti.py tmp/cn_bible/ \
      CUVt.sqlite3 CUVS.sqlite3 TSCharacters.txt STPhrases.txt STCharacters.txt
"""

import re
import shutil
import sqlite3
import sys
from collections import Counter
from difflib import SequenceMatcher
from pathlib import Path

TAG = re.compile(r"<[^>]+>")
PAIRED = re.compile(r"<[fnSm]>.*?</[fnSm]>", re.S)
MARKER = "\u3000\u795e"  # 　 + 神
SHEN = "\u795e"          # 神
SHANGDI = "\u4e0a\u5e1d" # 上帝
LETTER = re.compile(r"[\u3400-\u9fff\uf900-\ufaff0-9]")
SAMPLES = [(10, 1, 1), (50, 6, 4), (230, 23, 1), (500, 3, 16)]
# t2s-переопределения для сверки (CUVS пишет 着 там, где CUVt — 著; 藉 в таблице нет)
T2S_EXTRA = {"\u8457": "\u7740", "\u85c9": "\u501f"}  # 著 -> 着, 藉 -> 借 (сверка)
# нормализация упрощённого текста CUVS под современный стандарт
SIMP_POST = {"喫": "吃", "崙": "仑", "讬": "托"}
# s2t-фиксы под графикой печатных изданий (CUNP: 吃, 著, 裏, 姦)
S2T_OVERRIDES = {
    "\u7740": "\u8457",  # 着 -> 著
    "\u88e1": "\u88cf",  # 裡 -> 裏
    "\u5978": "\u59e6",  # 奸 -> 姦
    "\u5403": "\u5403",  # 吃 остаётся 吃 (как в современных изданиях, не 喫)
}
# фразы, которых нет в STPhrases или которые рвутся тегами: мука, зерно,
# 放松, 繫在, 天明了 (STPhrases даёт 明瞭 — «понятно», а тут «рассвело»),
# имена 希伯崙/以弗崙/迦斐託 как в печати (OpenCC дал бы 侖/托)
S2T_PHRASES = {
    "细面": "細麵", "麦面": "麥麵", "炒谷": "炒穀",
    "放松": "放鬆", "系在": "繫在", "明了": "明了",
    "希伯仑": "希伯崙", "以弗仑": "以弗崙", "迦斐托": "迦斐託",
}
# пост-замены в готовом традиционном тексте
S2T_POST = {
    "\u9eb2": "\u9eb5",  # 麪 -> 麵
    "\u738b\u5f8c": "\u738b\u540e",  # 王後 -> 王后 (царица)
}
# 1 Пар 22: нумерация CUVt сдвинута на 1 против CUVS (в CUVS есть 21:31,
# в CUVt его нет, но есть лишний 22:19): CUVS 22:k соответствует CUVt 22:k+1
REMAP_TRAD_KEY = {
    (130, 22, 5): (130, 22, 6),
    (130, 22, 6): (130, 22, 7),
    (130, 22, 10): (130, 22, 11),
    (130, 22, 17): (130, 22, 18),
    (130, 22, 18): (130, 22, 19),
}
PHRASE_MAX = 8


def plain(text: str) -> str:
    """Текст без разметки: <f>/<n>/<S>/<m> убираются с содержимым, прочие теги — без него."""
    return TAG.sub("", PAIRED.sub("", text or ""))


def display(text: str) -> str:
    return re.sub(r"\s+", " ", plain(text)).strip()


def load_table(path: Path, first_only=False) -> dict:
    """Словарь OpenCC: ключ -> значение (или список значений)."""
    table = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        key, _, values = line.partition("\t")
        vals = values.split()
        if vals:
            table[key.strip()] = vals[0] if first_only else vals
    return table


def t2s_convert(text: str, t2s: dict) -> str:
    return "".join(t2s.get(ch, ch) for ch in text)


def expected_letters(p_t: str, t2s: dict):
    """Буквы стиха CUVt (упр. графика) + индексы божественных 神."""
    letters = []
    divine_idx = set()
    prev = ""
    e = 0
    for ch in t2s_convert(p_t, t2s):
        if LETTER.match(ch):
            if ch == SHEN and prev == "\u3000":
                divine_idx.add(e)
            letters.append(ch)
            e += 1
        prev = ch
    return "".join(letters), divine_idx


def actual_letters(p_s: str) -> str:
    return "".join(ch for ch in p_s if LETTER.match(ch))


def ordinals_exact(a: str, divine_idx: set) -> set:
    ords = set()
    n = 0
    for i, ch in enumerate(a):
        if ch == SHEN:
            n += 1
            if i in divine_idx:
                ords.add(n)
    return ords


def ordinals_diff(e: str, a: str, divine_idx: set):
    """difflib-выравнивание: (ординалы, 神 без соответствия в equal-блоке, всего 神)."""
    ords = set()
    unmapped = 0
    n = 0
    idx_by_a = {}
    for op, i1, i2, j1, j2 in SequenceMatcher(None, e, a, autojunk=False).get_opcodes():
        if op == "equal":
            for j in range(j1, j2):
                idx_by_a[j] = i1 + (j - j1)
    for i, ch in enumerate(a):
        if ch == SHEN:
            n += 1
            if i in idx_by_a and idx_by_a[i] in divine_idx:
                ords.add(n)
            elif i not in idx_by_a:
                unmapped += 1
    return ords, unmapped, n


def replace_in_raw(raw: str, ordinals: set) -> str:
    """Замена k-х вхождений 神 в сыром тексте вне тегов."""
    out = []
    n = 0
    in_tag = False
    for ch in raw:
        if ch == "<":
            in_tag = True
        elif ch == ">":
            in_tag = False
        if not in_tag and ch == SHEN:
            n += 1
            out.append(SHANGDI if n in ordinals else ch)
        else:
            out.append(ch)
    return "".join(out)


def conv_seg_s2t(seg: str, phrases: dict, chars: dict, key, audit: list) -> str:
    res = []
    i = 0
    while i < len(seg):
        matched = False
        for ln in range(min(PHRASE_MAX, len(seg) - i), 1, -1):
            cand = seg[i:i + ln]
            if cand in S2T_PHRASES:
                res.append(S2T_PHRASES[cand])
                i += ln
                matched = True
                break
            if cand in phrases:
                res.append(phrases[cand])
                i += ln
                matched = True
                break
        if matched:
            continue
        ch = seg[i]
        if ch in S2T_OVERRIDES:
            res.append(S2T_OVERRIDES[ch])
            i += 1
            continue
        if ch in chars:
            res.append(chars[ch][0])
            if len(chars[ch]) > 1:
                audit.append((key, ch, "".join(chars[ch])))
            i += 1
            continue
        res.append(ch)
        i += 1
    return "".join(res)


def s2t_raw(raw: str, phrases: dict, chars: dict, key, audit: list) -> str:
    """Конвертация текста стиха вне тегов (теги переносятся как есть)."""
    out = []
    i = 0
    while i < len(raw):
        if raw[i] == "<":
            j = raw.find(">", i)
            j = len(raw) if j < 0 else j + 1
            out.append(raw[i:j])
            i = j
            continue
        j = raw.find("<", i)
        j = len(raw) if j < 0 else j
        out.append(conv_seg_s2t(raw[i:j], phrases, chars, key, audit))
        i = j
    return "".join(out)


def main():
    if len(sys.argv) != 7:
        sys.exit(__doc__)
    srcdir = Path(sys.argv[1])
    src_trad = srcdir / sys.argv[2]
    src_simp = srcdir / sys.argv[3]
    t2s_tbl = load_table(srcdir / sys.argv[4], first_only=True)
    t2s_tbl.update(T2S_EXTRA)
    s2t_phrases = {k: v[0] for k, v in load_table(srcdir / sys.argv[5]).items()}
    s2t_chars = load_table(srcdir / sys.argv[6])

    trad = sqlite3.connect(f"file:{src_trad}?mode=ro", uri=True)
    simp = sqlite3.connect(f"file:{src_simp}?mode=ro", uri=True)
    trad_rows = trad.execute(
        "SELECT rowid, book_number, chapter, verse, text FROM verses ORDER BY book_number, chapter, verse"
    ).fetchall()
    simp_rows = simp.execute(
        "SELECT rowid, book_number, chapter, verse, text FROM verses ORDER BY book_number, chapter, verse"
    ).fetchall()
    trad.close()
    simp.close()

    trad_by_key = {(b, c, v): t for _, b, c, v, t in trad_rows}
    simp_by_key = {(b, c, v): (rid, t) for rid, b, c, v, t in simp_rows}

    report = []
    say = report.append
    say(f"стихов: CUVt={len(trad_rows)} CUVS={len(simp_rows)}")
    only_trad = sorted(set(trad_by_key) - set(simp_by_key))
    only_simp = sorted(set(simp_by_key) - set(trad_by_key))
    if only_trad:
        say(f"есть только в CUVt: {only_trad}")
    if only_simp:
        say(f"есть только в CUVS: {only_simp}")

    # --- 1. Упрощённый 上帝版: позиции 神 из CUVt ---
    simp_new = {}             # key -> новый сырой текст
    manual = []                # (key, текст CUVS, текст CUVt)
    exact = diff_aligned = 0
    divine_in_cuvt = applied = lost_in_diff = 0
    for key, (rid, raw_s) in sorted(simp_by_key.items()):
        raw_t = trad_by_key.get(REMAP_TRAD_KEY.get(key, key))
        if raw_t is None:
            simp_new[key] = raw_s
            continue
        e, divine_idx = expected_letters(plain(raw_t), t2s_tbl)
        a = actual_letters(plain(raw_s))
        divine_in_cuvt += len(divine_idx)
        if e == a:
            ords = ordinals_exact(a, divine_idx)
            unmapped = 0
            exact += 1
        else:
            ords, unmapped, _ = ordinals_diff(e, a, divine_idx)
            diff_aligned += 1
        if unmapped:
            manual.append((key, raw_s, raw_t))
            simp_new[key] = raw_s  # стих не меняется до ручной проверки
            continue
        applied += len(ords)
        lost_in_diff += len(divine_idx) - len(ords)
        simp_new[key] = replace_in_raw(raw_s, ords) if ords else raw_s
        for frm, to in SIMP_POST.items():
            simp_new[key] = simp_new[key].replace(frm, to)
    say(f"упр.: сходятся посимвольно {exact}, выровнены difflib {diff_aligned}, "
        f"на ручную проверку {len(manual)}")
    say(f"упр.: божественных 神 в CUVt {divine_in_cuvt}, внесено в CUVS {applied}, "
        f"ушло с текстовыми расхождениями {lost_in_diff}, в ручных стихах "
        f"{divine_in_cuvt - applied - lost_in_diff}")
    if manual:
        say("стихи на ручную проверку (神 в неоднозначной зоне):")
        for key, raw_s, raw_t in manual:
            say(f"  {key[0]}:{key[1]}:{key[2]}\n    CUVS: {display(raw_s)}\n    CUVt: {display(raw_t)}")

    # --- 2. Традиционный 上帝版: s2t из готового упрощённого ---
    audit = []
    trad_new = {}
    for key, raw in simp_new.items():
        txt = s2t_raw(raw, s2t_phrases, s2t_chars, key, audit)
        for frm, to in S2T_POST.items():
            txt = txt.replace(frm, to)
        trad_new[key] = txt
    amb = Counter(f"{ch}->{vals}" for _, ch, vals in audit)
    say(f"трад.: неоднозначных иероглифов при s2t: {sum(amb.values())} "
        f"в {len({k for k, *_ in audit})} стихах: {dict(amb.most_common(12))}")

    # обратная сверка: буквы t2s(трад) == буквы(упр)
    roundtrip_bad = 0
    for key, raw_t in trad_new.items():
        e = "".join(t2s_tbl.get(ch, ch) for ch in plain(raw_t) if LETTER.match(ch))
        a = actual_letters(plain(simp_new[key]))
        if e != a:
            roundtrip_bad += 1
            if roundtrip_bad <= 10:
                pos = next((i for i, (x, y) in enumerate(zip(e, a)) if x != y), min(len(e), len(a)))
                say(f"  обратная сверка не сошлась {key[0]}:{key[1]}:{key[2]}: "
                    f"{e[max(0, pos-6):pos+6]} <> {a[max(0, pos-6):pos+6]}")
    say(f"трад.: обратная сверка (t2s(трад)==упр по буквам): не сошлись {roundtrip_bad} стихов")

    # --- 3. Запись модулей ---
    out_simp = srcdir / "cn-cuv.SQLite3"
    out_trad = srcdir / "cn-cuvt.SQLite3"
    for src, dst, new_texts, label, lang in (
        (src_simp, out_simp, simp_new, "cn-cuv", "zh Simplified"),
        (src_simp, out_trad, trad_new, "cn-cuvt", "zh Traditional"),
    ):
        shutil.copy2(src, dst)
        db = sqlite3.connect(dst)
        updates = [(txt, rid) for key, (rid, _) in simp_by_key.items() if (txt := new_texts[key]) is not None]
        db.executemany("UPDATE verses SET text=? WHERE rowid=?", updates)
        row = db.execute("SELECT value FROM info WHERE name='description'").fetchone()
        if row:
            db.execute(
                "UPDATE info SET value=? WHERE name='description'",
                (row[0] + " 【上帝版/Shangti edition: 　神→上帝, собрано из 神版 по издательскому маркеру — bibleox】",),
            )
        db.execute("UPDATE info SET value=? WHERE name='language'", (lang,))
        db.commit()
        db.close()
        n_god = sqlite3.connect(f"file:{dst}?mode=ro", uri=True).execute(
            "SELECT COUNT(*) FROM verses WHERE text LIKE ?", (f"%{SHANGDI}%",)
        ).fetchone()[0]
        say(f"модуль {label}: {dst} (обновлено стихов {len(updates)}, стихов с 上帝 {n_god})")

    # --- 4. Примеры ---
    say("")
    for path, label in ((out_simp, "упр."), (out_trad, "трад.")):
        db = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
        say(f"примеры ({label}):")
        for b, c, v in SAMPLES:
            row = db.execute(
                "SELECT text FROM verses WHERE book_number=? AND chapter=? AND verse=?", (b, c, v)
            ).fetchone()
            if row:
                say(f"  {b}:{c}:{v} {display(row[0])[:64]}")
        db.close()

    report_text = "\n".join(report)
    (srcdir / "shangti_report.txt").write_text(report_text + "\n", encoding="utf-8")
    print(report_text)


if __name__ == "__main__":
    main()
