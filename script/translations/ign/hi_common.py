#!/usr/bin/env python3
# Общие помощники для переводов посланий Игнатия на хинди (tmp/ign/hi_*.py)
import os
import re

ROOT = os.path.join(os.path.dirname(__file__), '..', '..')


def _book_abbrs():
    """Короткие названия книг из config/locales/hi.yml (books.short, по Hindi O.V.)"""
    text = open(os.path.join(ROOT, 'config/locales/hi.yml')).read()
    block = text.split('\n  books:\n    short:\n', 1)[1].split('\n    mid:', 1)[0]
    return dict(re.findall(r'^      (\S+): (.+)$', block, re.M))


ABBR = _book_abbrs()
EP = {'E': ('Ig3E_इफिसुस_की_कलीसिया_के_नाम_पत्र', 'इफिसुस की कलीसिया के नाम पत्र'),
      'M': ('Ig3M_मैग्नेशिया_की_कलीसिया_के_नाम_पत्र', 'मैग्नेशिया की कलीसिया के नाम पत्र'),
      'T': ('Ig3T_त्रालेस_की_कलीसिया_के_नाम_पत्र', 'त्रालेस की कलीसिया के नाम पत्र'),
      'R': ('Ig3R_रोम_की_कलीसिया_के_नाम_पत्र', 'रोम की कलीसिया के नाम पत्र'),
      'F': ('Ig3F_फिलदिलफिया_की_कलीसिया_के_नाम_पत्र', 'फिलदिलफिया की कलीसिया के नाम पत्र'),
      'S': ('Ig3S_स्मुरना_की_कलीसिया_के_नाम_पत्र', 'स्मुरना की कलीसिया के नाम पत्र'),
      'P': ('Ig3P_पॉलीकार्प_के_नाम_पत्र', 'पॉलीकार्प के नाम पत्र')}

# страница автора, в меню которой добавляются послания
LIST = 'Ig3A_अन्ताकिया_के_इग्नाटियस_पहली_शताब्दी'


def b(book, ch, vs, label=None):
    """Ссылка на стих в hi-ov: b('ef', 1, '4-5') -> इफि 1:4-5"""
    label = label or f"{ABBR[book]} {ch}:{vs}"
    return f'<a href="https://bibleox.com/hi/hi-ov/{book}/{ch}/#L{vs}">{label}</a>'


def i(ep, ch, sec=None):
    """Ссылка на главу послания Игнатия: i('M', 3, '1-2') -> «मैग्नेशिया की कलीसिया के नाम पत्र» 3:1-2"""
    path, title = EP[ep]
    ref = f"{ch}:{sec}" if sec else f"अध्याय {ch}"
    return f'<a href="https://bibleox.com/hi/hi/w/{path}#HH-{ch}">«{title}» {ref}</a>'


def here(ch, sec=None):
    """Ссылка на главу этого же послания"""
    ref = f"{ch}:{sec}" if sec else f"अध्याय {ch}"
    return f'<a href="#HH-{ch}">{ref}</a>'


def build(key, src, file_num, slug, ch_paras, notes, meta_desc, menu_priority, source_grc_path):
    """Проверяет сноски и пишет db/translations/hi/ign_{file_num}_{slug}.yml"""
    body_all = ''.join(''.join(v) for v in ch_paras.values())
    nums = [int(n) for n in re.findall(r'\[(\d+)\]', body_all)]
    assert nums == list(range(1, len(notes) + 1)), (nums, len(notes))
    path, title = EP[key]
    source = ("अनुवाद: रोडियन व्लासोव (एआई उपकरणों की सहायता से)। मूल पाठ: यूनानी मूल"
              f' (<a href="https://bibleox.com/hi/grc/w/{source_grc_path}">इस साइट का यूनानी संस्करण</a>; स्पष्ट छूटे हुए अंश लाइटफुट और होम्स के संस्करणों से पूरे किए गए)। '
              "सहायक अनुवाद: रूसी अनुवाद («प्रारम्भिक कलीसियाई पिता», ब्रसेल्स, 1988), अंग्रेज़ी अनुवाद (Roberts–Donaldson), फ़्रांसीसी अनुवाद (Genoude, 1837)। "
              "बाइबल के उद्धरण और लिंक हिन्दी O.V. के अनुसार।")
    body = '\n'.join(f"<h2>{ch}</h2>" + ''.join(f"<p>{p}</p>" for p in paras) for ch, paras in ch_paras.items())
    refs = '<ol>' + ''.join(f"<li><p>{n}</p></li>" for n in notes) + '</ol>\n<p>' + source + '</p>'
    os.makedirs(os.path.join(ROOT, 'db/translations/hi'), exist_ok=True)
    out = [
        f"# Игнатий Богоносец, «{src}»: перевод на хинди с греческого. Собирается из tmp/ign/hi_{slug}.py",
        f"# Загрузка: bin/rails pages:import_translations FILE=db/translations/hi/ign_{file_num}_{slug}.yml [PUBLISH=1] [DRY_RUN=1]",
        "lang: hi",
        f"list: {LIST}",
        "folders:",
        '  - { path: "पत्र", priority: 1 }',
        "pages:",
        f"  - src: {src}",
        f"    path: {path}",
        f"    title: {title}",
        f"    meta_desc: {meta_desc}",
        f'    menu: {{ parent: "पत्र", title: "{title}", priority: {menu_priority} }}',
        "    body: |-",
        *("      " + l for l in body.split('\n')),
        "    references: |-",
        *("      " + l for l in refs.split('\n')),
    ]
    open(os.path.join(ROOT, f'db/translations/hi/ign_{file_num}_{slug}.yml'), 'w').write('\n'.join(out) + '\n')
    print(f'{slug}: chapters {len(ch_paras)}, notes {len(notes)}')
