# Подготовка «сырого» тома Patrologia Latina к разбору: замена скриптов 1–3 из
# ~/Desktop/Библеокс/PL (gif→греческий, удаление <small>, [Col. → [PL]).
# BeautifulSoup в системе нет, поэтому всё делается регулярками и словарём из gif2gr.py.
#
#   python3 script/translations/pl/prep.py RAW.html VOLUME OUT.html
#
# Что делает:
#  - удаляет редакционные примечания <small>…</small> (включая вложенные);
#  - заменяет <img src="...pldgreek/NAME.gif"> на греческий символ или букву;
#  - [Col. 0123A] -> [PL16.123A];
#  - убирает обёртки таблиц/центрирования/надстрочных номеров страниц;
#  - нормализует nbsp и лишние пустые строки.

import ast
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
GIF2GR = os.path.join(HERE, 'gif2gr.py')


def load_greek():
    """Словарь gif2gr.py — это литерал словаря в файле, без присваивания."""
    src = open(GIF2GR, encoding='utf-8').read()
    body = src[src.index('{'):src.rindex('}') + 1]
    return ast.literal_eval(body)


def drop_small(html: str) -> str:
    """Удаляет <small>…</small> с учётом вложенности."""
    while True:
        new = re.sub(r'<small\b[^>]*>.*?</small>', ' ', html, count=1, flags=re.S | re.I)
        if new == html:
            return html
        html = new


def replace_gifs(html: str, table):
    def repl(m):
        src = m.group(1)
        name = os.path.basename(src.split('?')[0])
        if name.lower().endswith('.gif'):
            name = name[:-4]
        return table.get(name, m.group(0))

    return re.sub(r'<img\b[^>]*?src\s*=\s*["\']?([^"\'\s>]+)["\']?[^>]*>', repl, html, flags=re.I)


def main():
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    raw, volume, out = sys.argv[1], sys.argv[2], sys.argv[3]
    html = open(raw, encoding='utf-8', errors='replace').read()
    html = drop_small(html)
    html = replace_gifs(html, load_greek())
    html = re.sub(r'\[Col\.\s*0*', f'[PL{volume}.', html)
    html = re.sub(r'<sup>.*?</sup>', ' ', html, flags=re.S | re.I)
    html = re.sub(r'</?(?:tr|td|th|table|tbody|center)\b[^>]*>', ' ', html, flags=re.I)
    html = html.replace('\u00a0', ' ').replace('&nbsp;', ' ')
    html = re.sub(r'\n{3,}', '\n\n', html)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    open(out, 'w', encoding='utf-8').write(html)
    print(f'{out}: {len(html) // 1024} КБ')


if __name__ == '__main__':
    main()
