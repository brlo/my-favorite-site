# Собирает db/translations/trad/LANG.yml для TranslationImporter из tmp/trad/NAME.LANG.html
import re, json, os, sys
D = 'tmp/trad/'
LOC = dict(en='en', ja='ja', ko='ko', de='de', zh='zh-Hans', el='el')
LIB = dict(en='Library', ja='図書館', ko='도서관', de='Bibliothek', zh='图书馆', el='Βιβλιοθήκη')
CREDIT = dict(
  en='Translated from the Russian by Rodion Vlasov, with the help of AI. Bible quotations: NRSV.',
  ja='ロシア語からの翻訳：ロジオン・ヴラソフ（AIツールを併用）。聖書の引用は新共同訳による。',
  ko='러시아어에서 번역: 로디온 블라소프 (AI 도구 활용). 성경 인용은 개역개정에 따름.',
  de='Aus dem Russischen übersetzt von Rodion Wlassow, unter Verwendung von KI. Bibelzitate: Schlachter.',
  zh='译自俄语：罗季翁·弗拉索夫（借助人工智能）。圣经引文据思高本。',
  el='Μετάφραση από τα ρωσικά: Ροντιόν Βλάσοφ, με τη βοήθεια τεχνητής νοημοσύνης. Τα βιβλικά χωρία παρατίθενται στο πρωτότυπο.')
# name: (src ru path, path prefix, emoji, priority, has menu)
ART = [('icons', 'древние-иконы', 'Ik1c', '🖼️ ', 3, True), ('churches', 'Древние_христианские_храмы', 'Ch2c', '🪨 ', 4, True),
       ('burials', 'KPgB_Христианские_захоронения_и_надписи', 'Bu3i', '', 5, True), ('cook', '2NCD_Постная_кухня', 'Lc4k', '🍞 ', 9, True),
       ('icons2', 'bdRJ_Разные_древние_образы_не_вошедшие_в_основную_коллекцию', 'Ik5v', '', 0, False)]
PLACEHOLDER = dict(ko='🖼️ 성화(이콘)', de='🖼️ Ikonen', zh='🖼️ 圣像', el='🖼️ Εικόνες')
def slug(t): return re.sub(r'_+', '_', re.sub(r'[\s/]+', '_', re.sub(r'[«»“”„"(),.:;!?¿·、。，：；！？（）「」『』\'’]', '', t))).strip('_')
for lang in sys.argv[1:]:
  pages = []
  for name, src, pre, emoji, prio, menu in ART:
    f = D + f'{name}.{lang}.html'
    if not os.path.exists(f): continue
    title, sub, rest = open(f).read().split('\n', 2)
    body, refs = rest.split('\n==REFS==\n')
    refs = (refs.strip() + f'<p>{CREDIT[lang]}</p>')
    it = dict(src=src, path=f'{pre}_{slug(title)}', title=title, title_sub=sub or None, body=body.strip(), references=refs, copy_cover=True)
    if menu:
      it['menu'] = dict(parent=LIB[lang], title=emoji + title, priority=prio)
      if name == 'icons' and lang in PLACEHOLDER: it['menu']['replace'] = PLACEHOLDER[lang]
    if name == 'icons' and lang == 'ja': it['update'] = True
    pages.append(it)
  out = dict(lang=LOC[lang], list=f'links_{LOC[lang]}', pages=pages)
  head = f'# Раздел «Предание» (иконы, храмы, захоронения, постная кухня), перевод с русского. Собрано tmp/trad/yaml_build.py\n'
  json.dump(out, open(D + f"{lang}.json", "w"), ensure_ascii=False)
  print(lang, [p['path'] for p in pages])
