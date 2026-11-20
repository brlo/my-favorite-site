#!/usr/bin/env python3
"""Build EN body for Veselov disputes 7-10 (917-920) — extended labels edition.
Run from tmp/ (reads ru_paras_<id>.json and en_<id>_b*.json there).
Usage: veselov_build2.py <ru_id>
Reads: ru_paras_<id>.json (extract2), en_<id>_b*.json → body_en_<id>.html
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
    "Mt":"Matthew","Jn":"John","Lk":"Luke","Tit":"Titus","1Jn":"1 John","Mk":"Mark","Ex":"Exodus","Is":"Isaiah",
    "Act":"Acts","2Sol":"2 Thessalonians","1Sol":"1 Thessalonians","Ef":"Ephesians","Otkr":"Revelation",
    "Vtor":"Deuteronomy","Iud":"Jude","1Pet":"1 Peter","2Pet":"2 Peter","1Tim":"1 Timothy","2Tim":"2 Timothy",
    "Rim":"Romans","1Kor":"1 Corinthians","2Kor":"2 Corinthians","Prov":"Proverbs","Gal":"Galatians",
    "Fil":"Philippians","Iak":"James","Dan":"Daniel",
    "Iov":"Job","Zah":"Zechariah","Ier":"Jeremiah","Iez":"Ezekiel",
    "3Kg":"1 Kings","4Kg":"2 Kings",
}
# RU Synodal (LXX) numbering -> EN (Hebrew); every entry verified against NKJV verse text
PSALM_MAP = {
    "Ps50:7": "Psalm 51:5",
    "Ps5:8": "Psalm 5:7",
    "Ps6:6": "Psalm 6:5",
    "Ps113:25": "Psalm 115:17",
    "Ps145:3": "Psalm 146:3",
    "Ps33:9": "Psalm 34:8",
    "Ps84:11": "Psalm 85:10",
    "Ps44": "Psalm 45",
}
LABELS = {
    "Комментарий": "Comment",
    "Комментарии": "Comments",
    "Православный священник": "Orthodox priest",
    "Православный священник 2": "Orthodox priest 2",
    "Православный": "Orthodox",
    "Православный 2": "Orthodox 2",
    "Православный 3": "Orthodox 3",
    "Православный (докладчик)": "Orthodox (speaker)",
    "Православная": "Orthodox woman",
    "Православный 2 (сотрудник миссионерского отдела Московской епархии, бывший пастор пятидесятников)":
        "Orthodox 2 (staff member of the Missionary Department of the Moscow Diocese, a former Pentecostal pastor)",
    "Баптистский пастор": "Baptist pastor",
    "Баптистский пастор (докладчик)": "Baptist pastor (speaker)",
    "Баптистский пастор 2": "Baptist pastor 2",
    "Баптистский пастор 3": "Baptist pastor 3",
    "Баптист": "Baptist",
    "Баптист 2": "Baptist 2",
    "Баптист 3": "Baptist 3",
    "Баптист 4": "Baptist 4",
    "Приглашенный адвентист": "Invited Adventist",
    "Приглашенный адвентист 2": "Invited Adventist 2",
    "Пастор": "Pastor",
    "Алан": "Alan",
    "Ведущий": "Moderator",
}
TOKEN_RE = re.compile(r"\{([1-4]?[A-Za-z]+\d+(?::\d+)?(?:[-–]\d+)?)\}")

def render_verse(tok):
    if tok in PSALM_MAP:
        return PSALM_MAP[tok]
    m = re.match(r"^([1-4]?[A-Za-z]+?)(\d+)(?::(\d+))?(?:[-–](\d+))?$", tok)
    if not m or m.group(1) not in BOOKS:
        raise ValueError(f"unknown verse token: {tok}")
    book, ch, v, v2 = m.group(1), m.group(2), m.group(3), m.group(4)
    name = BOOKS[book]
    if book == "Ps":
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
    label_count = {}
    parts = []
    for p in ru:
        text = en[p["idx"]]
        def sub(m):
            tok = m.group(1)
            all_tokens.append(tok)
            if tok.startswith("Ps") and tok not in PSALM_MAP:
                ps_tokens.append(tok)
            return render_verse(tok)
        text = TOKEN_RE.sub(sub, text)
        assert not re.search(r"[\u0400-\u04FF]", re.sub(r'href="[^"]*"', "", text)), \
            f"cyrillic in EN #{p['idx']}: {text[:80]}"
        for tag in ("strong", "em", "a", "blockquote", "p", "h2"):
            o, c = len(re.findall(f"<{tag}[ >]", text)), text.count(f"</{tag}>")
            assert o == c, f"unbalanced <{tag}> in #{p['idx']}: open={o} close={c}"
        kind, label = p["kind"], p["label"]
        if kind == "h2":
            parts.append(f"<h2>{text}</h2>")
        elif kind == "bq":
            if label:
                assert label in ("Комментарий", "Комментарии"), f"unexpected bq label #{p['idx']}: {label}"
                parts.append(f"<blockquote><p><strong>{LABELS[label]}:</strong> {text}</p></blockquote>")
            else:
                parts.append(f"<blockquote><p>{text}</p></blockquote>")
        elif label:
            assert label in LABELS, f"unexpected label #{p['idx']}: {label}"
            label_count[LABELS[label]] = label_count.get(LABELS[label], 0) + 1
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
    for lab, n in sorted(label_count.items()):
        print(f"    {n:4} <strong>{lab}:</strong>")
    for x in ru:
        if x["kind"] == "h2":
            print("  h2:", en[x["idx"]][:80])

if __name__ == "__main__":
    main(sys.argv[1])
