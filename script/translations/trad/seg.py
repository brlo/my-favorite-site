# Перевод статей раздела «Предание» по сегментам: переводится только текст, разметка и картинки собираются заново.
#   python3 tmp/trad/seg.py extract NAME tmp/trad_X.html   -> tmp/trad/NAME.seg (ru-сегменты) + NAME.json (шаблон)
#   python3 tmp/trad/seg.py build NAME LANG                -> tmp/trad/NAME.LANG.html (body и references через ==REFS==)
# В переводе (tmp/trad/NAME.LANG.txt, блоки "### id"): {B3} — ссылка на стих из оригинала (подпись строится сама,
# {B3=ps 5:8} — другой адрес), {R in 10:11} — новая ссылка на стих, {a2}…{/a} — прочие ссылки, {I1} — картинки.
import json, re, sys, html as H

D = 'tmp/trad/'
LABELS = {  # подписи ссылок на картинки
  'крупнее': dict(en='larger', ja='拡大', ko='크게 보기', de='größer', zh='放大', el='μεγέθυνση'),
  'ещё крупнее': dict(en='even larger', ja='さらに拡大', ko='더 크게 보기', de='noch größer', zh='再放大', el='μεγαλύτερη μεγέθυνση'),
  'ещё рупнее': dict(en='even larger', ja='さらに拡大', ko='더 크게 보기', de='noch größer', zh='再放大', el='μεγαλύτερη μεγέθυνση'),
  'версия': dict(en='version', ja='別版', ko='다른 사진', de='Version', zh='版本', el='εκδοχή'),
  'кверсия': dict(en='version', ja='別版', ko='다른 사진', de='Version', zh='版本', el='εκδοχή'),
  'другая версия': dict(en='another version', ja='別版', ko='다른 사진', de='andere Version', zh='另一版本', el='άλλη εκδοχή'),
  'обратная сторона': dict(en='reverse side', ja='裏面', ko='뒷면', de='Rückseite', zh='背面', el='πίσω όψη'),
  'вид сверху': dict(en='top view', ja='上から', ko='위에서 본 모습', de='Ansicht von oben', zh='俯视', el='κάτοψη'),
  'вид сбоку': dict(en='side view', ja='側面', ko='옆에서 본 모습', de='Seitenansicht', zh='侧视', el='πλάγια όψη'),
  'внешний план': dict(en='exterior', ja='外観', ko='외관', de='Außenansicht', zh='外观', el='εξωτερική όψη'),
  'доп. фото': dict(en='extra photo', ja='追加写真', ko='추가 사진', de='weiteres Foto', zh='补充照片', el='επιπλέον φωτογραφία'),
}
LANGS = dict(en=('en', 'en-nrsv'), ja=('ja', 'jp-ni'), ko=('ko', 'ko-nkrv'), de=('de', 'ge-sch'), zh=('zh-Hans', 'cn-sb'), el=('el', 'gr-lxx-byz'))
BIBLE = re.compile(r'^https?://bibleox\.com/ru/(?:ru/)?([a-z0-9]+)/(\d+)/?(?:#L([\d,\-]+))?$')
IMG_HREF = re.compile(r'res\.bibleox\.com|\.(jpe?g|png|webp|gif)$', re.I)
BLOCK = re.compile(r'<(h2|h3|h4|p|li)>(.*?)</\1>', re.S)

def label(t, lang):
  t = t.strip(); m = re.match(r'^(.*?)\s*(\d+)$', t)
  if t in LABELS: return LABELS[t][lang]
  if m and m.group(1) in LABELS: return f'{LABELS[m.group(1)][lang]} {m.group(2)}'
  return None

def extract(name, path):
  src = open(path).read()
  title, sub, rest = src.split('\n', 2)
  body, refs = rest.split('\n==REFS==\n')
  tpl = {'title': title, 'sub': sub, 'parts': {}}; segs = [('title', title), ('sub', sub)] if sub.strip() else [('title', title)]
  n = [0]
  for part, h in (('body', body), ('refs', refs)):
    places = []
    def blk(m):
      tag, inner = m.group(1), m.group(2); ph = {}
      def a(mm):
        href, txt = mm.group(1), mm.group(2)
        if IMG_HREF.search(href) and label(txt, 'en'):
          k = f'L{len(ph)}'; ph[k] = ['L', href, txt.strip()]; return '{%s}' % k
        b = BIBLE.match(href)
        if b and b.group(1) != 'w':
          k = f'B{len(ph)}'; ph[k] = ['B', b.group(1), b.group(2), b.group(3) or '', txt]; return '{%s}' % k
        k = f'a{len(ph)}'; ph[k] = ['a', mm.group(0)[:mm.group(0).index('>') + 1]]; return '{%s}%s{/a}' % (k, txt)
      s = re.sub(r'<a\s[^>]*?href="([^"]*)"[^>]*>(.*?)</a>', a, inner, flags=re.S)
      def img(mm):
        k = f'I{len(ph)}'; ph[k] = ['I', mm.group(0)]; return '{%s}' % k
      s = re.sub(r'<img[^>]*>', img, s)
      n[0] += 1; sid = f'{part[0]}{n[0]}'
      plain = re.sub(r'\{/?[A-Za-z]\d*\}|<[^>]+>|[\s\[\]\(\).,;:—–\-*]|\d', '', s)
      places.append((sid, tag, ph, s if plain else None, s))
      if plain: segs.append((sid, s))
      return '\x00%s\x00' % sid
    skel = BLOCK.sub(blk, h)
    tpl['parts'][part] = {'skel': skel, 'blocks': {p[0]: {'tag': p[1], 'ph': p[2], 'src': p[4], 'tr': p[3] is not None} for p in places}}
  json.dump(tpl, open(D + name + '.json', 'w'), ensure_ascii=False, indent=0)
  with open(D + name + '.seg', 'w') as f:
    for sid, s in segs: f.write(f'### {sid}\n{s}\n')
  print(name, 'segments:', len(segs), 'chars:', sum(len(re.sub(r'\{[^}]*\}', '', s)) for _, s in segs))

def build(name, lang):
  tpl = json.load(open(D + name + '.json')); short = json.load(open(D + 'short.json'))[LANGS[lang][0]]
  loc, bib = LANGS[lang]
  tr = {}; cur = None
  for line in open(D + f'{name}.{lang}.txt').read().split('\n'):
    m = re.match(r'^### (\S+)\s*$', line)
    if m: cur = m.group(1); tr[cur] = []; continue
    if cur: tr[cur].append(line)
  tr = {k: '\n'.join(v).strip() for k, v in tr.items()}
  errs = []
  def blink(book, ch, vs, lab=None):
    b = bib
    if book.startswith('gr '): b, book = 'gr-lxx-byz', book[3:]  # книги нет в Библии языка: греческий текст
    href = f'https://bibleox.com/{loc}/{b}/{book}/{ch}/' + (f'#L{vs}' if vs else '')
    return f'<a href="{href}">{lab or (short.get(book, book) + " " + ch + (":" + vs if vs else ""))}</a>'
  def fill(sid, s, ph):
    def rep(m):
      k, ov = m.group(1), m.group(2)
      if k.startswith('R'):
        mm = re.match(r'R\s+((?:gr )?[a-z0-9]+)\s+(\d+)(?::([\d,\-]+))?$', k + (('=' + ov) if ov else ''))
        if not mm: errs.append(f'{sid}: bad {m.group(0)}'); return m.group(0)
        return blink(mm.group(1), mm.group(2), mm.group(3))
      p = ph.get(k)
      if not p: errs.append(f'{sid}: unknown {k}'); return m.group(0)
      if p[0] == 'I': return p[1]
      if p[0] == 'L': return f'<a href="{p[1]}">{label(p[2], lang)}</a>'
      if p[0] == 'a':
        # страницы сайта не на русском (греческие тексты и т. п.): интерфейс на языке перевода
        return re.sub(r'(https?://bibleox\.com/)ru/(?!ru/)([a-z]{2,3}/)', lambda x: x.group(1) + loc + '/' + x.group(2), p[1])
      if p[0] == 'B':
        book, ch, vs = p[1], p[2], p[3]
        if ov:
          mm = re.match(r'((?:gr )?[a-z0-9]+)\s+(\d+)(?::([\d,\-]+))?$', ov.strip()); book, ch, vs = mm.group(1), mm.group(2), mm.group(3) or ''
        return blink(book, ch, vs)
    s = re.sub(r'\{(R [^}=]+|[A-Za-z]\d+)(?:=([^}]*))?\}', rep, s)
    return s.replace('{/a}', '</a>')
  out = {}
  for part, P in tpl['parts'].items():
    def put(m):
      sid = m.group(1); b = P['blocks'][sid]
      if b['tr']:
        if sid not in tr:
          s = b['src']
          if re.search('[а-рт-яё]', re.sub(r'<a\s[^>]*>|https?://\S+', '', s), re.I): errs.append(f'{sid}: no translation')
        else: s = tr[sid]
        used = set(re.findall(r'\{([ILBa]\d+)', s)); need = {k for k in b['ph'] if k[0] in 'IL'}
        if need - used: errs.append(f'{sid}: lost {sorted(need - used)}')
      else: s = b['src']
      return f"<{b['tag']}>{fill(sid, s, b['ph'])}</{b['tag']}>"
    out[part] = re.sub('\x00(\\w+)\x00', put, P['skel'])
  for e in errs: print('ERR', e)
  title = tr.get('title', tpl['title']); sub = tr.get('sub', '')
  open(D + f'{name}.{lang}.html', 'w').write(f"{title}\n{sub}\n{out['body']}\n==REFS==\n{out['refs']}")
  print(name, lang, 'ok' if not errs else f'{len(errs)} errors')

if __name__ == '__main__':
  {'extract': extract, 'build': build}[sys.argv[1]](*sys.argv[2:])
