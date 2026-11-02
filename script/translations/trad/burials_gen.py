# Собирает burials.LANG.txt: латынь/греческий из английского файла, глоссы и текст — из словарей burials_LANG.py
import re, sys, importlib.util
Q = dict(ja=('「', '」'), ko=('“', '”'), de=('„', '“'), zh=('“', '”'), el=('«', '»'))
en = open('burials.en.txt').read()
blocks = re.findall(r'### (\S+)\n(.*?)(?=\n### |\Z)', en, re.S)
for lang in sys.argv[1:]:
  spec = importlib.util.spec_from_file_location('d', f'burials_{lang}.py'); d = importlib.util.module_from_spec(spec); spec.loader.exec_module(d); G = d.G
  o, c = Q[lang]; out = []
  for sid, txt in blocks:
    n = sid[1:]
    if sid in G: t = G[sid]
    elif 'g' + n in G:
      g = G['g' + n]
      m = re.match(r'^(.*—\s*)<strong>“.*”</strong>(.*)$', txt, re.S)
      if m: t = f'{m.group(1)}<strong>{o}{g}{c}</strong>{m.group(2)}'
      else:
        m = re.match(r'^(<p>.*?–\s*)“<strong>.*?</strong>”(.*)</p>$', txt, re.S)
        tail = G.get('g' + n + 'x', '')
        t = f'{m.group(1)}{o}<strong>{g}</strong>{c}{("。" if lang in ("ja","zh") else ".") if not tail else ""}{tail}</p>' if m else None
      if t is None: print('NO MATCH', lang, sid); t = txt
    else: print('MISSING', lang, sid); t = txt
    out.append(f'### {sid}\n{t}')
  open(f'burials.{lang}.txt', 'w').write('\n'.join(out) + '\n')
