#!/usr/bin/env python3
"""Extract RU paragraphs of a Veselov article into numbered JSON for translation.
Usage: veselov_extract.py <ru_id>
Writes paragraphs_<id>.json: [{idx, kind: p|bq|h2, label, text}]  (text = plain RU, refs as-is)
"""
import re, json, sys
from pathlib import Path

def main(pid):
    t = Path(__file__).parent / "veselov_review" / f"body_{pid}.html"
    html = t.read_text()
    parts = re.findall(r"<p[^>]*>(.*?)</p>|<blockquote[^>]*>(.*?)</blockquote>|<h2[^>]*>(.*?)</h2>", html, re.S)
    out = []
    for i, (p, bq, h2) in enumerate(parts):
        raw = p or bq or h2
        kind = "p" if p else ("bq" if bq else "h2")
        # speaker/label detection on markup (labels wrapped in <strong>, colon inside or outside)
        label = ""
        m = re.match(r"^(?:<p[^>]*>)?(?:<strong>)?\s*(Комментари[ейи]*|Баптист(?:ский пастор)?|Православный(?: священник)?|Пастор|Алан|Ведущий)\s*(?:</strong>)?\s*[.:]?\s*(?:</strong>)?\s*", raw)
        if m:
            label = m.group(1)
            raw = raw[m.end():]
        text = re.sub(r"\s+", " ", raw).strip()
        out.append({"idx": i, "kind": kind, "label": label, "text": text})
    dest = Path(__file__).parent / f"ru_paras_{pid}.json"
    dest.write_text(json.dumps(out, ensure_ascii=False, indent=1))
    print(f"paras={len(out)} bq={sum(1 for x in out if x['kind']=='bq')} h2={sum(1 for x in out if x['kind']=='h2')} labels={sum(1 for x in out if x['label'])}")
    print("labels:", sorted({x['label'] for x in out if x['label']}))

if __name__ == "__main__":
    main(sys.argv[1])
