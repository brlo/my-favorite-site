#!/usr/bin/env python3
"""Учит s2t-карту на паре cn-cuv → cn-cuvt из базы (TSV из COPY).

Выученная карта точнее «слепого» OpenCC: она отражает реальную графикy
cn-cuvt (爲 не 為, 交托 не 交託, 喂→餵, 家具 без 傢 и т.д.).

TSV: book\tchapter\tline\tsimp\ttrad   (поля 4 и 5 могут содержать табы? нет —
COPY с 5 колонками; тексты не содержат табов).

Usage: python3 build_charmap.py /tmp/verse_pairs.tsv tmp/cn_bible/s2t_db.json
"""
import difflib
import json
import sys
from collections import Counter, defaultdict

CJK = re.compile(r"[\u3400-\u9fff\uf900-\ufaff]") if False else None
import re  # noqa: E402
CJK = re.compile(r"[\u3400-\u9fff\uf900-\ufaff]")


def main():
    pairs_path, out_path = sys.argv[1], sys.argv[2]
    char_votes = defaultdict(Counter)
    phrase_votes = Counter()

    with open(pairs_path, encoding="utf-8") as f:
        for line in f:
            parts = line.rstrip("\n").split("\t")
            if len(parts) != 5:
                continue
            _b, _c, _v, simp, trad = parts
            # чистим разметку: <f>…</f>, <n>…</n> с содержимым; прочие теги — без
            def clean(t):
                t = re.sub(r"<[fnSm]>.*?</[fnSm]>", "", t, flags=re.S)
                t = re.sub(r"</?[a-zA-Z]+>", "", t)
                return t
            s, t = clean(simp), clean(trad)
            if not s or not t:
                continue
            sm = difflib.SequenceMatcher(None, s, t, autojunk=False)
            for op, i1, i2, j1, j2 in sm.get_opcodes():
                if op == "equal":
                    # голосуем и за совпадения: иначе редкие варианты
                    # (面→麪 в паре стихов о хлебах) перебивают мажоритарный 面→面
                    a, b = s[i1:i2], t[j1:j2]
                    for x, y in zip(a, b):
                        if CJK.match(x):
                            char_votes[x][y] += 1
                    continue
                a, b = s[i1:i2], t[j1:j2]
                if not a or not b:
                    continue
                if len(a) == len(b) == 1:
                    char_votes[a][b] += 1
                elif len(a) <= 6 and len(b) <= 6 and CJK.search(a) and CJK.search(b):
                    phrase_votes[(a, b)] += 1
                else:
                    # длинные блоки: учим попарно по выравниванию внутри блока
                    sm2 = difflib.SequenceMatcher(None, a, b, autojunk=False)
                    for op2, k1, k2, l1, l2 in sm2.get_opcodes():
                        if op2 == "equal":
                            continue
                        a2, b2 = a[k1:k2], b[l1:l2]
                        if len(a2) == len(b2) == 1:
                            char_votes[a2][b2] += 1
                        elif 1 < len(a2) <= 6 and 1 < len(b2) <= 6 and CJK.search(a2):
                            phrase_votes[(a2, b2)] += 1

    charmap = {a: c.most_common(1)[0][0] for a, c in char_votes.items()}
    phrases = {a: b for (a, b), n in phrase_votes.items() if n >= 3 and a != b}
    data = {"chars": charmap, "phrases": phrases}
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=0)
    print(f"chars: {len(charmap)}, phrases: {len(phrases)}")


if __name__ == "__main__":
    import re
    main()
