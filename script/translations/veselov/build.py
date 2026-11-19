#!/usr/bin/env python3
"""Build EN body for Veselov article from RU structure + EN translations.
Usage: veselov_build.py <ru_id> [suffix]
Reads: ru_paras_<id>.json, en_<id>_b*.json  →  body_en_<id>.html
"""
import re, json, sys, glob
from pathlib import Path

BOOKS = {
    "Gen":"Genesis","Exod":"Exodus","Lev":"Leviticus","Num":"Numbers","Deut":"Deuteronomy",
    "Josh":"Joshua","Judg":"Judges","Ruth":"Ruth","1Sam":"1 Samuel","2Sam":"2 Samuel",
    "1Kg":"1 Kings","2Kg":"2 Kings","1Chr":"1 Chronicles","2Chr":"2 Chronicles",
    "Ezra":"Ezra","Neh":"Nehemiah","Esth":"Esther","Job":"Job","Ps":"Psalm",
    "Prov":"Proverbs","Eccl":"Ecclesiastes","Song":"Song of Songs","Isa":"Isaiah","Jer":"Jeremiah",
    "Lam":"Lamentations","Ezek":"Ezekiel","Dan":"Daniel","Hos":"Hosea","Joel":"Joel",
    "Amos":"Amos","Obad":"Obadiah","Jonah":"Jonah","Mic":"Micah","Nah":"Nahum",
    "Hab":"Habakkuk","Zeph":"Zephaniah","Hag":"Haggai","Zech":"Zechariah","Mal":"Malachi",
    "Wis":"Wisdom","Sir":"Sirach",
    "Matt":"Matthew","Mark":"Mark","Luke":"Luke","John":"John","Acts":"Acts","Rom":"Romans",
    "1Cor":"1 Corinthians","2Cor":"2 Corinthians","Gal":"Galatians","Eph":"Ephesians",
    "Phil":"Philippians","Col":"Colossians","1Thess":"1 Thessalonians","2Thess":"2 Thessalonians",
    "1Tim":"1 Timothy","2Tim":"2 Timothy","Titus":"Titus","Phlm":"Philemon","Heb":"Hebrews",
    "Jas":"James","1Pet":"1 Peter","2Pet":"2 Peter","Jude":"Jude","Rev":"Revelation",
    # aliases used in translation tokens
    "Mt":"Matthew","Jn":"John","Lk":"Luke","Tit":"Titus","1Jn":"1 John","Mk":"Mark","Ex":"Exodus","Is":"Isaiah","Josh":"Joshua","2Kg":"2 Kings","1Kg":"1 Kings","2Sam":"2 Samuel","1Sam":"1 Samuel",
}
# Psalms: RU Synodal (LXX) numbering -> EN (Hebrew). Verified against verse text.
PSALM_MAP = {
    "Ps50:7": "Psalm 51:5",
    "Ps5:8": "Psalm 5:7",
    "Ps6:6": "Psalm 6:5",
    "Ps113:25": "Psalm 115:17",
    "Ps145:3": "Psalm 146:3",
}
LABELS = {
    "Православный": "Orthodox",
    "Православный священник": "Orthodox priest",
    "Баптистский пастор": "Baptist pastor",
    "Баптист": "Baptist",
    "Пастор": "Pastor",
    "Алан": "Alan",
    "Ведущий": "Moderator",
    "Комментарий": "Comment",
    "Комментарии": "Comments",
}
TOKEN_RE = re.compile(r"\{([12]?[A-Za-z]+\d+(?::\d+)?(?:[-–]\d+)?)\}")

def render_ref(tok):
    if tok in PSALM_MAP:
        return PSALM_MAP[tok]
    m = re.match(r"^([12]?[A-Za-z]+?)(\d+)(?:[-–](\d+))?$", tok)
    if not m or m.group(1) not in BOOKS:
        raise ValueError(f"unknown ref token: {tok}")
    book, ch, v2 = m.group(1), m.group(2), m.group(3)
    name = BOOKS[book]
    if v2:
        return f"{name} {ch}–{v2}" if book == book else f"{name} {ch}–{v2}"
    return f"{name} {ch}"

def render_verse(tok):
    # full form: Book Ch:V or Book Ch:V–V2 or Book Ch (chapter-only)
    if tok in PSALM_MAP:
        return PSALM_MAP[tok]
    m = re.match(r"^([12]?[A-Za-z]+?)(\d+)(?::(\d+))?(?:[-–](\d+))?$", tok)
    if not m or m.group(1) not in BOOKS:
        raise ValueError(f"unknown verse token: {tok}")
    book, ch, v, v2 = m.group(1), m.group(2), m.group(3), m.group(4)
    name = BOOKS[book]
    if book == "Ps" and tok not in PSALM_MAP:
        raise ValueError(f"psalm token needs verified mapping: {tok}")
    if v and v2:
        return f"{name} {ch}:{v}–{v2}"
    if v:
        return f"{name} {ch}:{v}"
    if v2:
        return f"{name} {ch}–{v2}"
    return f"{name} {ch}"

def main(pid):
    d = Path(__file__).parent
    ru = json.loads((d / f"ru_paras_{pid}.json").read_text())
    en = {}
    for f in sorted(glob.glob(str(d / f"en_{pid}_b*.json"))):
        en.update({int(k): v for k, v in json.loads(Path(f).read_text()).items()})
    missing = [p["idx"] for p in ru if p["idx"] not in en]
    extra = [k for k in en if k not in {p["idx"] for p in ru}]
    assert not missing, f"missing translations: {missing[:20]}"
    assert not extra, f"extra translations: {extra[:20]}"

    ps_tokens, all_tokens = [], []
    parts = []
    for p in ru:
        text = en[p["idx"]]
        # resolve verse tokens
        def sub(m):
            tok = m.group(1)
            all_tokens.append(tok)
            if tok.startswith("Ps") and tok not in PSALM_MAP:
                ps_tokens.append(tok)
            return render_verse(tok)
        text = TOKEN_RE.sub(sub, text)
        # checks
        assert not re.search(r"[\u0400-\u04FF]", re.sub(r'href="[^"]*"', '', text)), f"cyrillic in EN #{p['idx']}: {text[:80]}"
        for tag in ("strong", "em", "a", "blockquote", "p", "h2"):
            o, c = len(re.findall(f"<{tag}[ >]", text)), text.count(f"</{tag}>")
            assert o == c, f"unbalanced <{tag}> in #{p['idx']}: open={o} close={c}"
        kind, label = p["kind"], p["label"]
        if kind == "h2":
            parts.append(f"<h2>{text}</h2>")
        elif kind == "bq":
            assert label in ("Комментарий", "Комментарии"), f"unexpected bq label #{p['idx']}: {label}"
            parts.append(f"<blockquote><p><strong>{LABELS[label]}</strong>: {text}</p></blockquote>")
        elif label:
            assert label in LABELS, f"unexpected label #{p['idx']}: {label}"
            parts.append(f"<p><strong>{LABELS[label]}:</strong> {text}</p>")
        else:
            parts.append(f"<p>{text}</p>")
    assert not ps_tokens, f"psalm tokens without verified mapping: {ps_tokens}"
    body = "".join(parts)
    assert "{" not in body and "}" not in body, "unresolved braces remain in body"
    out = d / f"body_en_{pid}.html"
    out.write_text(body)
    ru_refs = sum(len(re.findall(r"\d+[:.]\d+", x["text"])) for x in ru if x["kind"] != "h2")
    print(f"OK: {len(ru)} paras -> {out.name}, {len(body)} chars, {len(all_tokens)} refs (RU had ~{ru_refs} verse-cites)")
    # h2 preview
    for x in ru:
        if x["kind"] == "h2":
            print("  h2:", en[x["idx"]][:70])

if __name__ == "__main__":
    main(sys.argv[1])
