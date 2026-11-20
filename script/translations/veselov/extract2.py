#!/usr/bin/env python3
"""Extract RU paragraphs of Veselov disputes 7-10 (917-920) with FULL label handling.
Run from tmp/ (reads tmp/veselov_review/body_<id>.html, writes ru_paras_<id>.json).
Usage: veselov_extract2.py <ru_id>...
Writes ru_paras_<id>.json: [{idx, kind: p|bq|h2, label, text}]
- labels (speaker marks) are stripped from text and normalized (typos fixed);
- leading dashes after labels are stripped;
- h2 markup is stripped to plain text;
- everything else (participants block, inline strong/em, refs) kept as-is.
"""
import re, json, sys
from pathlib import Path

# canonical RU labels the extractor may strip (anything else stays inline)
KNOWN = {
    "Комментарий", "Комментарии",
    "Православный священник", "Православный священник 2",
    "Православный", "Православный 2", "Православный 3",
    "Православный (докладчик)",
    "Православная",
    "Православный 2 (сотрудник миссионерского отдела Московской епархии, бывший пастор пятидесятников)",
    "Баптистский пастор", "Баптистский пастор (докладчик)",
    "Баптистский пастор 2", "Баптистский пастор 3",
    "Баптист", "Баптист 2", "Баптист 3", "Баптист 4",
    "Приглашенный адвентист", "Приглашенный адвентист 2",
    "Пастор", "Алан", "Ведущий",
}

def canon_label(s):
    s = re.sub(r"\s+", " ", s).strip()
    if s.startswith("Комментари"):
        s = s.rstrip(".:").strip()
    # strip trailing colon/dash pairs in any order ("Label: – ", "Label –:", ...)
    while True:
        t = s.rstrip(":–—-").strip()
        if t == s:
            break
        s = t
    # typos seen in transcripts
    s = s.replace("Баптист2", "Баптист 2").replace("Баптистс 2", "Баптист 2")
    # "(2)" -> " 2"; fix unclosed paren from broken markup
    s = re.sub(r"\((\d)\)", r" \1", s)
    s = re.sub(r"\(докладчик(?!\))", "(докладчик)", s)
    # unify
    s = s.replace("Православный докладчик", "Православный (докладчик)")
    s = re.sub(r"\s+", " ", s).strip()
    return s

def split_label(raw):
    """Return (label, rest) if paragraph starts with a known speaker label."""
    raw = raw.lstrip()
    m = re.match(r"^<strong>([^<]+)</strong>\s*([:.–—-]?)\s*", raw)
    if m:
        lab = canon_label(m.group(1))
        rest = raw[m.end():]
        if lab in KNOWN:
            rest = re.sub(r"^[.:–—-]\s*", "", rest.lstrip())
            rest = re.sub(r"^[–—-]\s*", "", rest)  # dash after label
            return lab, rest.strip()
    return "", raw.strip()

def main(pid):
    html = (Path(__file__).parent / "veselov_review" / f"body_{pid}.html").read_text()
    parts = re.findall(r"<p[^>]*>(.*?)</p>|<blockquote[^>]*>(.*?)</blockquote>|<h2[^>]*>(.*?)</h2>", html, re.S)
    out = []
    for i, (p, bq, h2) in enumerate(parts):
        if h2:
            text = re.sub(r"<[^>]+>", "", h2)
            text = re.sub(r"\s+", " ", text).strip().rstrip(":").strip()
            out.append({"idx": i, "kind": "h2", "label": "", "text": text})
            continue
        raw, kind = (p, "p") if p else (bq, "bq")
        raw = re.sub(r"\s+", " ", raw).strip()
        if kind == "bq":  # blockquote content is wrapped in <p>…</p>
            raw = re.sub(r"^<p[^>]*>", "", raw)
            raw = re.sub(r"</p>$", "", raw).strip()
        label, text = split_label(raw)
        out.append({"idx": i, "kind": kind, "label": label, "text": text})
    dest = Path(__file__).parent / f"ru_paras_{pid}.json"
    dest.write_text(json.dumps(out, ensure_ascii=False, indent=1))
    print(f"{pid}: paras={len(out)} bq={sum(1 for x in out if x['kind']=='bq')} h2={sum(1 for x in out if x['kind']=='h2')} labels={sum(1 for x in out if x['label'])}")
    from collections import Counter
    for lab, n in Counter(x["label"] for x in out if x["label"]).most_common():
        print(f"    {n:4} {lab}")
    unknown = [x for x in out if x["text"].startswith("<strong>") and not x["label"]
               and (m := re.match(r"^<strong>([^<]+)</strong>", x["text"]))
               and canon_label(m.group(1)) in KNOWN]
    if unknown:
        print("    !! paras that still look label-headed:", [x["idx"] for x in unknown][:10])

if __name__ == "__main__":
    for arg in sys.argv[1:]:
        main(arg)
