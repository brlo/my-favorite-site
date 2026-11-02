# Заменяет выделяемые фразы в строках цитат исходника: python3 script/translations/q_setph.py FILE < правки
# Правка — строка «НОМЕР| фраза :: !фраза ...»; ссылка и примечание (~~) в строке исходника сохраняются.
import sys
path = sys.argv[1]
lines = open(path, encoding='utf-8').read().split('\n')
for row in sys.stdin.read().strip().split('\n'):
    if not row.strip():
        continue
    num, phrases = row.split('|', 1)
    i = int(num) - 1
    line = lines[i]
    assert line.startswith('> '), (num, line)
    head, _, note = line[2:].partition(' ~~ ')
    ref = head.split(' :: ')[0].rstrip(' :')
    phrases = phrases.strip()
    lines[i] = '> ' + ref + (' :: ' + phrases if phrases else '') + (' ~~ ' + note if note else '')
open(path, 'w', encoding='utf-8').write('\n'.join(lines))
