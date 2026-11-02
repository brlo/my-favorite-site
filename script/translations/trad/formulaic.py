# Переводит шаблонные подписи (даты, музеи, размеры) из icons.en.txt на de/zh/el; остальное — список для ручного перевода
import re, sys, json
M = {
 'de': [("The Metropolitan Museum of Art, Fifth Avenue, USA", "Metropolitan Museum of Art, Fifth Avenue, USA"), ("The Louvre, France", "Louvre, Frankreich"), ("The Hermitage, Russia", "Eremitage, Russland"), ("The Cleveland Museum of Art, USA", "Cleveland Museum of Art, USA"), ("The British Museum", "British Museum")],
 'zh': [("The Metropolitan Museum of Art, Fifth Avenue, USA", "大都会艺术博物馆（第五大道，美国）"), ("The Louvre, France", "卢浮宫（法国）"), ("The Hermitage, Russia", "艾尔米塔什博物馆（俄罗斯）"), ("The Cleveland Museum of Art, USA", "克利夫兰艺术博物馆（美国）"), ("The British Museum", "大英博物馆")],
 'el': [("The Metropolitan Museum of Art, Fifth Avenue, USA", "Μητροπολιτικό Μουσείο Τέχνης, Πέμπτη Λεωφόρος, ΗΠΑ"), ("The Louvre, France", "Λούβρο, Γαλλία"), ("The Hermitage, Russia", "Ερμιτάζ, Ρωσία"), ("The Cleveland Museum of Art, USA", "Μουσείο Τέχνης του Κλίβελαντ, ΗΠΑ"), ("The British Museum", "Βρετανικό Μουσείο")],
}
W = {
 'de': {'Material: ': 'Material: ', 'Size: ': 'Größe: ', 'Diameter: ': 'Durchmesser: ', 'Height: ': 'Höhe: ', 'Silver': 'Silber', 'silver': 'Silber', 'Ivory': 'Elfenbein', 'ivory': 'Elfenbein', 'Bronze': 'Bronze', 'gold': 'Gold', 'Gold': 'Gold', 'Linen': 'Leinen', 'Wool': 'Wolle', 'Glass, gold leaf': 'Glas, Blattgold', 'gilding': 'Vergoldung', 'engraving': 'Gravur', 'See also: ': 'Siehe auch: ', 'Mosaic': 'Mosaik', 'Fresco': 'Fresko', 'weight': 'Gewicht'},
 'zh': {'Material: ': '材料：', 'Size: ': '尺寸：', 'Diameter: ': '直径：', 'Height: ': '高：', 'Silver': '银', 'silver': '银', 'Ivory': '象牙', 'ivory': '象牙', 'Bronze': '青铜', 'gold': '金', 'Gold': '金', 'Linen': '亚麻', 'Wool': '羊毛', 'Glass, gold leaf': '玻璃、金箔', 'gilding': '镀金', 'engraving': '雕刻', 'See also: ': '另见：', 'Mosaic': '马赛克', 'Fresco': '壁画', 'weight': '重量'},
 'el': {'Material: ': 'Υλικό: ', 'Size: ': 'Διαστάσεις: ', 'Diameter: ': 'Διάμετρος: ', 'Height: ': 'Ύψος: ', 'Silver': 'Άργυρος', 'silver': 'άργυρος', 'Ivory': 'Ελεφαντόδοντο', 'ivory': 'ελεφαντόδοντο', 'Bronze': 'Χαλκός', 'gold': 'χρυσός', 'Gold': 'Χρυσός', 'Linen': 'Λινό', 'Wool': 'Μαλλί', 'Glass, gold leaf': 'Γυαλί, φύλλο χρυσού', 'gilding': 'επιχρύσωση', 'engraving': 'χάραξη', 'See also: ': 'Βλέπε επίσης: ', 'Mosaic': 'Ψηφιδωτό', 'Fresco': 'Τοιχογραφία', 'weight': 'βάρος'},
}
ORD = {'de': lambda n: f'{n}.', 'zh': lambda n: f'{n}', 'el': lambda n: f'{n}ος'}
def cent(lang, t):
  def one(m):
    a, b = m.group(1), m.group(3)
    if lang == 'de': return f'{a}.' + (f'–{b}. Jahrhundert' if b else ' Jahrhundert')
    if lang == 'zh': return f'{a}' + (f'—{b}世纪' if b else '世纪')
    return f'{a}ος' + (f'–{b}ος αιώνας' if b else ' αιώνας')
  t = re.sub(r'(\d+)(?:st|nd|rd|th)(?:[–-](\d+)(?:st|nd|rd|th))? century', lambda m: one(re.match(r'(\d+)()(\d+)?', m.group(1) + ('' if not m.group(2) else '') ) if False else None) or '', t) if False else t
  t = re.sub(r'(\d+)(?:st|nd|rd|th)(–(\d+)(?:st|nd|rd|th))? century', one, t)
  return t
en = open('icons.en.txt').read()
blocks = re.findall(r'### (\S+)\n(.*?)(?=\n### |\Z)', en, re.S)
for lang in sys.argv[1:]:
  auto, manual = {}, []
  for sid, t in blocks:
    if int(re.sub(r'\D', '', sid) or 0) < 175 and sid[0] == 'b': continue
    if sid in ('title', 'sub'): continue
    s = t
    for a, b in M[lang]: s = s.replace(a, b)
    for a, b in W[lang].items(): s = s.replace(a, b)
    s = cent(lang, s)
    s = s.replace('c. ', {'de': 'um ', 'zh': '约', 'el': 'περ. '}[lang])
    if lang == 'de': s = re.sub(r'(\d)\.(\d)', r'\1,\2', s)
    if lang == 'zh': s = s.replace('. ', '。').replace('; ', '；').rstrip('.') + ('。' if t.rstrip().endswith('.') else '')
    rest = re.sub(r'\{[^}]*\}|https?://\S+|\b(cm|mm|g|ml|in|USA|Louvre|Metropolitan|Museum|Art|Fifth|Avenue|Cleveland|British|of|the|Frankreich|Russland|Eremitage|Jahrhundert|um|Größe|Material|Silber|Elfenbein|Bronze|Gold|Leinen|Wolle|Glas|Blattgold|Vergoldung|Gravur|Siehe|auch|Mosaik|Fresko|Gewicht|Durchmesser|Höhe)\b', '', s)
    if re.search(r'[A-Za-z]{3,}', rest) and lang != 'el' or (lang == 'el' and re.search(r'[A-Za-z]{3,}', re.sub(r'\{[^}]*\}|https?://\S+|\b(cm|mm|g|ml)\b', '', s))) or (lang == 'zh' and re.search(r'[A-Za-z]{3,}', re.sub(r'\{[^}]*\}|https?://\S+|\b(cm|mm|g|ml|in)\b', '', s))):
      manual.append(sid)
    else: auto[sid] = s
  json.dump(auto, open(f'icons.{lang}.auto.json', 'w'), ensure_ascii=False, indent=0)
  print(lang, 'auto', len(auto), 'manual', len(manual)); print(' '.join(manual))
