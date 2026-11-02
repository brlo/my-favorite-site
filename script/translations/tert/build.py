# Собирает YAML для TranslationImporter из tmp/tert/<name>.txt
# Формат: первая строка-метаданные "key: value" до пустой строки, затем главы:
#   ## Заголовок главы
#   абзац
# Сноска пишется прямо в тексте: {{текст}} -> [n] + пункт в <ol>; нумерация сквозная.
# После @@@ — строки о переводе в конце references.
import json, re, sys

name = sys.argv[1]
src = open(f'tmp/tert/{name}.txt', encoding='utf-8').read()
head, rest = src.split('\n\n', 1)
meta = dict(line.split(': ', 1) for line in head.splitlines())
rest, tail = rest.split('@@@')

notes = []
def note(m):
    notes.append(m.group(1).strip())
    return f'[{len(notes)}]'

body = [f"<p><strong>{meta['intro']}</strong></p>"] if meta.get('intro') else []
n = 0
for block in re.split(r'\n\s*\n', rest.strip()):
    block = ' '.join(block.split())
    block = re.sub(r'\{\{(.+?)\}\}', note, block)
    if block.startswith('## '):
        n += 1
        body.append(f'<h2>{n}. {block[3:]}</h2>')
    else:
        body.append(f'<p>{block}</p>')

refs = '<ol>' + ''.join(f'<li><p>{x}</p></li>' for x in notes) + '</ol>'
refs += ''.join(f'<p>{x.strip()}</p>' for x in tail.strip().splitlines() if x.strip())

data = {'lang': 'ru', 'list': meta['list'], 'pages': [{
    'src': meta['path'], 'title': meta['title'], 'title_sub': meta.get('sub') or None,
    'meta_desc': meta['desc'], 'body': ''.join(body), 'references': refs, 'update': True,
}]}
# JSON — подмножество YAML, а PyYAML на хосте нет
json.dump(data, open(f'tmp/tert/out_{name}.yml', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
print(name, 'глав', n, 'сносок', len(notes), 'знаков', len(''.join(body)))
