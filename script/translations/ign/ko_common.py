#!/usr/bin/env python3
# Общие помощники для корейских (ko) переводов посланий Игнатия (tmp/ign/ko_*.py)
import os
import re

ROOT = os.path.join(os.path.dirname(__file__), '..', '..')


def _book_abbrs():
    """Короткие названия книг из config/locales/ko.yml (books.short, по 공동번역)"""
    text = open(os.path.join(ROOT, 'config/locales/ko.yml')).read()
    block = text.split('\n  books:\n    short:\n', 1)[1].split('\n    mid:', 1)[0]
    return dict(re.findall(r'^      (\S+): (.+)$', block, re.M))


ABBR = _book_abbrs()
EP = {'E': ('Ig2E_에페소교회에보낸편지', '에페소 교회에 보낸 편지'),
      'M': ('Ig2M_마그네시아교회에보낸편지', '마그네시아 교회에 보낸 편지'),
      'T': ('Ig2T_트랄레스교회에보낸편지', '트랄레스 교회에 보낸 편지'),
      'R': ('Ig2R_로마교회에보낸편지', '로마 교회에 보낸 편지'),
      'F': ('Ig2F_필라델피아교회에보낸편지', '필라델피아 교회에 보낸 편지'),
      'S': ('Ig2S_스미르나교회에보낸편지', '스미르나 교회에 보낸 편지'),
      'P': ('Ig2P_폴리카르포스에게보낸편지', '폴리카르포스에게 보낸 편지')}

# страница автора, в меню которой добавляются послания
LIST = 'Ig2A_안티오키아의이그나티오스1세기'


def b(book, ch, vs, label=None):
    """Ссылка на стих в ko-ctb: b('ef', 1, '4-5') -> 에페 1:4-5"""
    label = label or f"{ABBR[book]} {ch}:{vs}"
    return f'<a href="https://bibleox.com/ko/ko-ctb/{book}/{ch}/#L{vs}">{label}</a>'


def i(ep, ch, sec=None):
    """Ссылка на главу послания Игнатия: i('M', 3, '1-2') -> 「마그네시아 교회에 보낸 편지」 3:1-2"""
    path, title = EP[ep]
    ref = f"{ch}:{sec}" if sec else f"{ch}장"
    return f'<a href="https://bibleox.com/ko/ko/w/{path}#HH-{ch}">「{title}」 {ref}</a>'


def here(ch, sec=None):
    """Ссылка на главу этого же послания"""
    ref = f"{ch}:{sec}" if sec else f"{ch}장"
    return f'<a href="#HH-{ch}">{ref}</a>'


def build(key, src, file_num, slug, ch_paras, notes, meta_desc, menu_priority, source_grc_path):
    """Проверяет сноски и пишет db/translations/ko/ign_{file_num}_{slug}.yml"""
    body_all = ''.join(''.join(v) for v in ch_paras.values())
    nums = [int(n) for n in re.findall(r'\[(\d+)\]', body_all)]
    assert nums == list(range(1, len(notes) + 1)), (nums, len(notes))
    path, title = EP[key]
    source = ("번역: 로디온 블라소프 (AI 도구 활용). 저본: 그리스어 원문"
              f'(<a href="https://bibleox.com/ko/grc/w/{source_grc_path}">이 사이트의 그리스어판</a>. 명백한 누락은 라이트풋판과 홈스판으로 보충함). '
              "참고: 러시아어 번역(『초기 교부 선집』, 브뤼셀, 1988년), 영어 번역(Roberts–Donaldson), 프랑스어 번역(Genoude, 1837년). "
              "성경 인용과 링크는 공동번역 성서에 따름.")
    body = '\n'.join(f"<h2>{ch}</h2>" + ''.join(f"<p>{p}</p>" for p in paras) for ch, paras in ch_paras.items())
    refs = '<ol>' + ''.join(f"<li><p>{n}</p></li>" for n in notes) + '</ol>\n<p>' + source + '</p>'
    os.makedirs(os.path.join(ROOT, 'db/translations/ko'), exist_ok=True)
    out = [
        f"# Игнатий Богоносец, «{src}»: корейский перевод с греческого. Собирается из tmp/ign/ko_{slug}.py",
        f"# Загрузка: bin/rails pages:import_translations FILE=db/translations/ko/ign_{file_num}_{slug}.yml [PUBLISH=1] [DRY_RUN=1]",
        "lang: ko",
        f"list: {LIST}",
        "folders:",
        '  - { path: "편지", priority: 1 }',
        "pages:",
        f"  - src: {src}",
        f"    path: {path}",
        f"    title: {title}",
        f"    meta_desc: {meta_desc}",
        f'    menu: {{ parent: "편지", title: "{title}", priority: {menu_priority} }}',
        "    body: |-",
        *("      " + l for l in body.split('\n')),
        "    references: |-",
        *("      " + l for l in refs.split('\n')),
    ]
    open(os.path.join(ROOT, f'db/translations/ko/ign_{file_num}_{slug}.yml'), 'w').write('\n'.join(out) + '\n')
    print(f'{slug}: chapters {len(ch_paras)}, notes {len(notes)}')
