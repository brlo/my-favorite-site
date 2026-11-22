# Автопроверки собранных страниц PL до импорта.
#
#   python3 script/translations/pl/check.py tmp/pl/4/plan.json
#
# Ошибки (exit 1): нет маркеров столбцов, чужие тома, редакционный аппарат в теле,
# запрещённые теги, непарные теги, мягкие переносы, HTML-сущности, страница > 450 КБ.
# Предупреждения: маркеры столбцов идут назад (опечатка набора Migne), пробелы перед знаками.

import json
import re
import sys

# Однозначные следы редакторского аппарата (не латинские слова «admonitio», «capitula»)
APPARATUS = [
    (r'\b(?:Erasm|Pamel|Baluz|Oxon|Lips|Coustant|Galland|Bod|Lam|Voss|Morell|Manut|Rig)\.[\s.]', 'ссылка на издание'),
    (r'\bEdidit\b', 'Edidit'),
    (r'\bpag\.\s*\d', 'pag. N'),
    (r'\bVid\.\s*(?:tom|not)', 'Vid. tom'),
    (r'\[Note:', '[Note:'),
    (r'\bARGUMENTUM\.---', 'ARGUMENTUM.---'),
    (r'\bCAPITULA\s*LIBRI\b', 'CAPITULA LIBRI'),
    (r'\bpraefatio in editionem\b', 'praefatio in editionem'),
]
BAD_TAGS = ['<small', '<sup', '<td', '<tr', '<center', '<br']


def check(page, volume):
    body = page['body']
    errors, warnings = [], []
    # дополнительные тома, на которые ссылаются примечания (добор писем из t. 3)
    allowed = {str(volume)} | set(re.findall(r't\.\s*(\d+),\s*coll', page.get('references', '')))
    markers = re.findall(r'\[PL(\d+)\.(\d+)([A-Z]?)\]', body)
    if not markers and not page.get('no_markers'):
        errors.append('нет маркеров столбцов')
    else:
        vols = {v for v, _, _ in markers}
        if not vols <= allowed:
            errors.append(f'чужие тома в маркерах: {sorted(vols - allowed)}')
        # порядок проверяем внутри каждого тома отдельно
        for vol in sorted(vols):
            nums = [int(n) for v, n, _ in markers if v == vol]
            back = [(nums[i], nums[i + 1]) for i in range(len(nums) - 1) if nums[i] > nums[i + 1]]
            if back:
                warnings.append(f'маркеры t. {vol} идут назад {len(back)} раз: {back[:3]}')

    for pattern, name in APPARATUS:
        if re.search(pattern, body, re.S):
            errors.append(f'редакционный аппарат: {name}')
    for tag in BAD_TAGS:
        if tag in body.lower():
            errors.append(f'запрещённый тег: {tag}')
    if body.count('<p>') != body.count('</p>'):
        errors.append('непарные <p>')
    if body.count('<h2>') != body.count('</h2>') or body.count('<h3>') != body.count('</h3>'):
        errors.append('непарные заголовки')
    if '\u00ad' in body:
        errors.append('мягкий перенос U+00AD')
    if re.search(r'&[a-z]+;', body):
        errors.append('HTML-сущность в теле')
    if len(body) > 460_000:
        errors.append(f'страница больше 450 КБ ({len(body)//1024} КБ)')
    text = re.sub(r'<[^>]+>', ' ', body)
    if re.search(r'\s+[,.;:]', text):
        warnings.append('пробел перед знаком препинания')
    return errors, warnings


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    plan = json.load(open(sys.argv[1], encoding='utf-8'))
    volume = plan.get('volume') or int(re.search(r'/pl/(\d+)/', sys.argv[1]).group(1))
    print(f"автор: {plan['author']['path']} — {plan['author']['title']}")
    print(f"трудов: {len(plan['pages'])}, папок: {len(plan.get('folders', []))}")
    failed = 0
    for page in plan['pages']:
        errors, warnings = check(page, volume)
        status = 'FAIL' if errors else ('WARN' if warnings else 'OK  ')
        failed += bool(errors)
        print(f"{status} {page['path']:<30} {len(page['body'])//1024:>4} КБ  "
              f"h2={page['body'].count('<h2>')} h3={page['body'].count('<h3>')}  {page['title'][:42]}")
        for e in errors:
            print('       ✗', e)
        for w in warnings:
            print('       ~', w)
    if failed:
        sys.exit(1)
    print('\nошибок нет' + (', есть предупреждения' if any(check(p, volume)[1] for p in plan['pages']) else ''))


if __name__ == '__main__':
    main()
