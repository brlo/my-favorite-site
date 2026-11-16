#!/usr/bin/env python3
"""zh-Hans → zh-Hant конвертер исходников раздела цитат (и произвольного текста).

Использует те же таблицы OpenCC и те же фиксы, что и сборка cn-cuvt
(script/translations/bible/build_shangti.py): STPhrases (макс. 8 знаков,
longest-match) + STCharacters (первое значение) + оверрайды печатной графики
(着→著, 裡→裏, 姦→姦...) + S2T_PHRASES + S2T_POST. Благодаря этому фразы
выделений из конвертированных исходников дословно сходятся со стихами
cn-cuvt, которые проверяет q_build/chk_q.

Usage:
  python3 convert.py <in.txt> <out.txt>
  python3 convert.py --dir <srcdir> <outdir>   # все *.txt + q_00_folders.yml

Разметка не трогается: теги <...> пропускаются целиком, кириллица/латиница
(пути [[ru:...]], ASCII-ссылки, @@ src) конвертацию не затрагивает.
"""
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
TABLES = REPO / "tmp" / "cn_bible"
PHRASE_MAX = 9

# фиксы печатной графики и библейских имён (как в cn-cuvt)
S2T_PHRASES = {
    "云彩": "云彩",  # cn-cuvt сохраняет 云彩 (не 雲綵)
    "察出": "察出", "使公义和赞美": "使公義和贊美", "转回": "轉回", "沾染": "沾染", "转回": "轉回", "你们转回": "你們轉回", "转回，转回吧": "轉回，轉回吧",
        "叫他们吃祭偶像之物": "叫他們吃祭偶像之物",
    "和你们吃": "和你們吃", "一切干渴": "一切幹渴", "什么相干": "什麼相幹",
    "用神迹奇事": "用神跡奇事", "又饥、又渴": "又飢、又渴",
    "背着他的十字架": "揹着他的十字架", "你们吃园中": "你們吃園中", "交托": "交托", "扎了我的手": "紮了我的手", "所扎的人": "所扎的人", "也不再有占卜的": "也不再有佔卜的", "情欲": "情欲",
    "细面": "細麵", "麦面": "麥麵", "炒谷": "炒穀",
    "放松": "放鬆", "系在": "繫在", "明了": "明了",
    "希伯仑": "希伯崙", "以弗仑": "以弗崙", "迦斐托": "迦斐託",
}
S2T_OVERRIDES = {
    "着": "著", "裡": "裏", "奸": "姦", "吃": "吃",
}
S2T_POST = {
    "麪": "麵",
    "王後": "王后",  # царица, не «после»
    # OpenCC-измы, расходящиеся с графикой cn-cuvt:
    "紮": "扎", "矇": "蒙", "啓": "啟", "捱": "挨",
    "綵": "彩", "两只手": "兩隻手",
}

TAG = re.compile(r"<[^<>]*>")


def load_db_map(path: Path) -> tuple[dict, dict]:
    """Карта, выученная на паре cn-cuv → cn-cuvt (build_charmap.py)."""
    import json
    data = json.loads(path.read_text(encoding="utf-8"))
    return data["chars"], data["phrases"]


def load_table(path: Path, first_only=False) -> dict:
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


def conv_seg(seg: str, phrases: dict, chars: dict) -> str:
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
        elif ch in chars:
            res.append(chars[ch][0])
        else:
            res.append(ch)
        i += 1
    return "".join(res)


def s2t(raw: str, phrases: dict, chars: dict) -> str:
    """Конвертация вне тегов <...>; сами теги переносятся как есть."""
    out = []
    i = 0
    while i < len(raw):
        if raw[i] == "<" and i + 1 < len(raw) and (raw[i + 1].isascii() and raw[i + 1].isalpha() or raw[i + 1] in "/!"):
            j = raw.find(">", i)
            j = len(raw) if j < 0 else j + 1
            out.append(raw[i:j])
            i = j
            continue
        j = raw.find("<", i + 1)
        j = len(raw) if j < 0 else j
        out.append(conv_seg(raw[i:j], phrases, chars))
        i = j
    return "".join(out)


def convert_text(raw: str, phrases: dict, chars: dict) -> str:
    res = s2t(raw, phrases, chars)
    for a, b in S2T_POST.items():
        res = res.replace(a, b)
    return res


def main():
    tables = TABLES
    db_chars, db_phrases = load_db_map(tables / "s2t_db.json")
    # выученная по базе карта главнее OpenCC; фразы-константы главнее всего
    phrases = {**load_table(tables / "STPhrases.txt", first_only=True), **db_phrases}
    chars = {**load_table(tables / "STCharacters.txt", first_only=True), **db_chars}

    args = sys.argv[1:]
    if args and args[0] == "--dir":
        srcdir, outdir = Path(args[1]), Path(args[2])
        outdir.mkdir(parents=True, exist_ok=True)
        files = sorted(p for p in srcdir.glob("*.txt") if not p.name.startswith(("cmp_judge", "verses_all")))
        for p in files:
            out = convert_text(p.read_text(encoding="utf-8"), phrases, chars)
            (outdir / p.name).write_text(out, encoding="utf-8")
            print(f"{p.name}: {len(out)}")
        fy = srcdir / "q_00_folders.yml"
        if fy.exists():
            (outdir / "q_00_folders.yml").write_text(
                convert_text(fy.read_text(encoding="utf-8"), phrases, chars), encoding="utf-8")
            print("q_00_folders.yml")
        return

    inp, outp = args[0], args[1]
    out = convert_text(Path(inp).read_text(encoding="utf-8"), phrases, chars)
    Path(outp).write_text(out, encoding="utf-8")
    print(f"{outp}: {len(out)}")


if __name__ == "__main__":
    main()
