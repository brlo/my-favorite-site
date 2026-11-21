# Добор писем Киприана из PL 3 (том III Migne) — тех, у которых в PL 4 напечатано
# только резюме (Migne сам отсылает их к тому III).
#
#   python3 script/translations/pl/supplement.py script/translations/pl/manifests/pl3_letters.json
#
# На входе — прогнанный PL3.html (greek_replaced), на выходе — tmp/pl/3/supplements/ep_<номер>.html
# (тело письма: абзацы <p>, без заголовков — номер и название письма уже стоят в PL 4).
#
# Начало текста: первый абзац после резюме — либо приветствие («…salutem»), либо
# нумерованный раздел («I. …»); всё до него (заголовки, ARGUMENTUM, примечания) отбрасывается.
# Конец — заголовок следующего труда из манифеста.

import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import extract  # noqa: E402  (переиспользуем разбор блоков и чистку)

START_RE = re.compile(r'^(?:\[PL[3]\.[\dA-Z]+\]\s*)*(?:[IVXLC]+\.\s+)?.*\bsalutem\b', re.I)
SECTION_RE = re.compile(r'^(?:\[PL[3]\.[\dA-Z]+\]\s*)*[IVXLC]+\.\s+[A-Z]')


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    manifest = json.load(open(sys.argv[1], encoding='utf-8'))
    src = manifest['source']
    out_dir = manifest.get('out', 'tmp/pl/3/supplements')
    os.makedirs(out_dir, exist_ok=True)
    blocks = extract.parse_blocks(open(src, encoding='utf-8').read())

    def find_block(prefix, after=0):
        for i in range(after, len(blocks)):
            tag, txt, _ = blocks[i]
            if tag != 'p' and re.match(prefix, extract.clean_heading(txt)):
                return i
        return None

    report = []
    for letter in manifest['letters']:
        start = find_block(letter['start'])
        if start is None:
            print(f"!! {letter['number']}: не найден {letter['start']}")
            continue
        end = find_block(letter['end'], start + 1) or len(blocks)
        body, stats = [], {'markers': 0, 'paragraphs': 0, 'chars': 0}
        started = False
        for tag, txt, raw in blocks[start:end]:
            if tag != 'p':
                continue                      # заголовки не нужны: номер письма из PL 4
            p = extract.clean_paragraph(txt)
            if not p or extract.SKIP_PARAGRAPH.match(p) or extract.NOTE_RE.match(p):
                continue
            if not started:
                flat = extract.MARKER_RE.sub(' ', p).strip()
                if START_RE.match(flat) or SECTION_RE.match(flat):
                    started = True
                else:
                    continue                  # ARGUMENTUM, примечания редактора, пролог
            if re.match(r'^(?:\[PL3\.[\dA-Z]+\]\s*)*ARGUMENT', p, re.I):
                continue
            body.append(f'<p>{p}</p>')
            stats['markers'] += len(extract.MARKER_RE.findall(p))
            stats['paragraphs'] += 1
        html = '\n'.join(body)
        stats['chars'] = len(extract.MARKER_RE.sub('', extract.TAG_RE.sub('', html)))
        fn = os.path.join(out_dir, f"ep_{letter['number']}.html")
        open(fn, 'w', encoding='utf-8').write(html + '\n')
        report.append(f"Ep. {letter['number']:<5} {stats['chars']:>6} симв  p={stats['paragraphs']:>3}  "
                      f"маркеров={stats['markers']:>3}  <- {letter['source']}")
        print(report[-1])
    open(os.path.join(out_dir, 'report.txt'), 'w', encoding='utf-8').write('\n'.join(report) + '\n')


if __name__ == '__main__':
    main()
