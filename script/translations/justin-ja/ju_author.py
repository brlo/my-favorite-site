#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Авторская страница Иустина Философа (ru 389) -> db/translations/ja/ju_00_author.yml
# Цитаты Q1-Q95 — дословно из ja-трудов (спеки из quotes_auto.json + ручные композиты);
# Q96-Q101 — отзывы других отцов (перевод с ru, вне вербатим-проверки).
import sys, os, re, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'quadratus'))
from ja_common import build

HERE = os.path.dirname(os.path.abspath(__file__))
from ju_author_body1 import BODY1
from ju_author_body2 import BODY2

WORKS = {
    'A1': '/Users/brlo/Sites/bibleox/db/translations/ja/ju_01_a1.yml',
    'A2': '/Users/brlo/Sites/bibleox/db/translations/ja/ju_02_a2.yml',
    'Dial': '/Users/brlo/Sites/bibleox/db/translations/ja/ju_03_dialog.yml',
}

def load_work_paras():
    out = {}
    for key, fn in WORKS.items():
        ytext = open(fn, encoding='utf-8').read()
        body = ytext.split('    body: |-\n',1)[1].split('    references: |-',1)[0]
        body = '\n'.join((l[6:] if l.startswith('      ') else l) for l in body.split('\n'))
        parts = re.split(r'<h2[^>]*>([^<]+)</h2>', body)
        d = {}
        for i in range(1, len(parts), 2):
            title = parts[i].strip()
            text = parts[i+1] if i+1 < len(parts) else ''
            m = re.match(r'(\d+)', title)
            num = int(m.group(1)) if m else 0
            d[num] = re.findall(r'<p[^>]*>(.*?)</p>', text, flags=re.S)
        out[key] = d
    return out

WP = load_work_paras()

def plain(t):
    return re.sub(r'\s+', '', re.sub(r'\[\d+\]', '', re.sub(r'<[^>]+>', '', t)))

def html_slice(p_html, p_from, p_to):
    mapping = []
    i = 0
    while i < len(p_html):
        if p_html[i] == '<':
            j = p_html.find('>', i)
            if j < 0: j = len(p_html) - 1
            i = j + 1
            continue
        mapping.append((i, i + 1))
        i += 1
    if p_from >= len(mapping) or p_to > len(mapping) or p_from >= p_to:
        return None
    return p_html[mapping[p_from][0]:mapping[p_to - 1][1]]

def extract_fragment(work, num, ps, pe, st, en):
    # маркеры сносок из труда в цитате авторской страницы не сохраняются (прецедент Климента)
    paras = [re.sub(r'\[\d+\]', '', p) for p in WP[work].get(num, [])]
    if ps >= len(paras) or pe >= len(paras):
        return None, f'para range {ps}-{pe} vs {len(paras)}'
    plain_ps = plain(paras[ps])
    p_from = plain_ps.find(plain(st))
    if p_from < 0:
        for k in range(ps, pe + 1):
            q = plain(paras[k]).find(plain(st))
            if q >= 0:
                ps, p_from = k, q
                break
        else:
            return None, f'start not found in paras {ps}-{pe}: "{st}"'
    p_to = None
    pe_k = pe
    for k in range(ps, pe + 1):
        pk = plain(paras[k])
        start_at = p_from if k == ps else 0
        q = pk.find(plain(en), start_at)
        if q >= 0:
            p_to = q + len(plain(en))
            pe_k = k
            break
    else:
        return None, f'end not found after start in paras {ps}-{pe}: "{en}"'
    if ps == pe_k:
        frag = html_slice(paras[ps], p_from, p_to)
        if frag is None:
            return None, 'slice fail'
        return '<p>' + frag + '</p>', None
    parts = []
    f1 = html_slice(paras[ps], p_from, len(plain(paras[ps])))
    parts.append(f1)
    for k in range(ps + 1, pe_k):
        parts.append(paras[k])
    f2 = html_slice(paras[pe_k], 0, p_to)
    parts.append(f2)
    if any(p is None for p in parts):
        return None, 'slice fail multi'
    return ''.join('<p>%s</p>' % p for p in parts), None

# ---------------------------------------------------------------- реестр
AUTO = json.load(open(os.path.join(HERE, 'quotes_auto.json')))
# {n_str: [(work, num, ps, pe, st, en), ...]}

# ручные композиты (фрагменты маркерами по фактическому тексту ja-трудов)
MANUAL = {
    12: [('Dial', 48, 0, 0, 'あなたは、このキリストが世の前に存在する神', '不合理に見えます。'),
         ('Dial', 48, 1, 1, '——わたしは知っています', 'おとめから人として生まれたことを証明できなかったとしても。'),
         ('Dial', 48, 1, 1, 'わたしたちの種族の中には、皆さん', '信じるようにと命じられたのですから。')],
    21: [('Dial', 67, 5, 5, '——さらに、あなたに尋ねましょう', 'かたくなさと偶像礼拝への傾きのゆえにですか。'),
         ('Dial', 67, 6, 6, '——聖書は、後者を認めることを強います', '言いました。'),
         ('Dial', 22, 0, 0, 'さらに、あなたたちの民の罪と偶像礼拝のゆえに', '語ることをお聞きください。'),
         ('Dial', 22, 0, 0, 'それゆえ、神はあなたたちからの献げ物を受け取らない', '言葉によって裏付けられます。'),
         ('Dial', 43, 0, 0, 'それゆえ、もしあなたたちの民のかたくなさのゆえに', '止まるはずであったでしょう。')],
    28: [('A1', 23, 0, 0, 'この教えをわたしたちに授けたのは', '回復するためにです。'),
         ('A1', 63, 0, 0, 'この子は、神の初めて生まれたロゴス', '死を打ち勝つためです。')],
    35: [('Dial', 138, 0, 0, 'キリスト——すべての被造物の中の初生の子', '木の上で救われたのと同じように。'),
         ('Dial', 138, 0, 0, 'わたしは意味しています', '来る神の裁きを避けるであろうことを。'),
         ('Dial', 44, 0, 0, 'どのような道を通して自分の罪の赦し', '罪なしに生きること。')],
    40: [('Dial', 117, 0, 0, 'それゆえ、神は、イエス・キリストが行うようにと命じられた', 'が退けられます。'),
         ('Dial', 117, 0, 0, 'わたしは同意します', '受難を思い起こすのです。'),
         ('Dial', 29, 0, 0, 'その方は異邦人たちにも好意を示され', 'その方に喜ばれるのですから。'),
         ('Dial', 41, 0, 0, 'そして小麦の粉の供え物', '聖体のパンの前型でした。')],
}

# Q96-Q101 — отзывы других отцов (перевод с ru; вне вербатим-проверки)
QTEXT = {
    96: 'わたしたちが、語り、反駁した主題について、恣意的な作り物を用いたなどと、だれかに責められるとは考えません。それらの主題については、聖なる照らされた人たち——異端の祖たちの先達でもあり、同時代人でもあった人たち——が語り、反駁しています。ユスティノス、哲学者にして致命者。ミルティアデス、教会たちの擁護者。エイレナイオス、このような教えのすべてを探究した学ある人。わたしたちのプロクロス、老いたるまでの貞潔の人、キリストの告白の名誉と栄光。神が、信仰のほかの労苦においても、そしてわたしの前に置かれたこの仕事においても、わたしが彼らに並ぶことを賜りますように。',
    97: 'ユスティノス・ネアポリタス——時においても徳においても使徒たちから遠くない男——は、死すべきものが相続されるが、命は相続されず、肉は死ぬが天の御国は生きる、と語っています。',
    98: 'タティアノス。タティアノスは、聖なる致命者にして哲学者であるユスティノスの同時代人でした。そして、致命者にして哲学者であるユスティノスの死の後に、マルキオンの弟子となり、その教義によって堕落し、彼と同じことを教え、マルキオンに付け加えるものさえ付け加えました。彼はメソポタミアの出であると語られています。……これらの者の後に、あるタティアノスが立ち上がりました。あるいは、彼らの時代に生きていた人、あるいは彼らの後に自分の空しい教えを提出した人。彼は初めには、エリン人たちの出であり、エリンの教養を持っていたので、ユスティノス（哲学者）の同時代人でした。聖なる人、神の友——サマリヤからキリストを信じた人。このユスティノスは、サマリヤ人であり、キリストを信じ、偉大な労苦を成し遂げ、徳ある生を現し、ついに、ルストゥクス総督とアドリアヌス帝のもとで、キリストのゆえに致命を受け、若い年齢——すなわち三十歳——のうちに完全な栄冠を授けられました。',
    99: 'しかし、わたしたちの語りが、すでに水下の岩々と危険な場所から抜け出たので、帆を広げて、その方のエピロゴイへと進まなければなりません。その中で、その人は、自分を専門家と考えながら、テルトゥリアヌスを証人として呼び、ペタウィオの主教ヴィクトリヌスの言葉を挙げます。テルトゥリアヌスについては、その人が教会の人ではなかったと言うほかには何も語りません。そしてヴィクトリヌスについては、福音書記者たちについて主張するのと同じことを主張します。すなわち、彼らは主の兄弟たちについて語ったのであって、マリヤの子たちについてではなく、わたしたちが先に示した意味での、本性ではなく親族による兄弟たちについて語った、と。しかし、わたしたちは、つまらないことについて論じています。真理の泉を残して、意見の小さな流れを追いかけながら。わたしは、あなたに、古代の書き手たちの列全体を挙げることができないでしょうか。イグナティオス、ポリュカルポス、エイレナイオス、ユスティノス致命者、そしてほかの多くの使徒的で学ある人たち。彼らは、エビオンにたいして、そしてテオドトスにたいして、ビザンティオンにたいして、ヴァレンティノスにたいして、同じ仕方で論じながら、知恵に満ちた著作を書いたのです。',
    100: 'ユスティノス、パレスチナの都ネアポリスの出の哲学者、プリスクスとバキウスの子は、キリストの教えの益のために熱心に労働しました。……ついに、ユスティノスは、キリスト者であったことで告発され、クレセンセスの尽力によって、キリストのために自分の血を注ぎました。',
    101: '聖なる教父たちの誰が、この同じ教えを宣言しなかったでしょうか。……そして彼の教師アレクサンドロスは、これらの教義〔神について〕のために戦いました。同じような人たちとして、エウスタティオス、メレティオス、フラウィアノス——東方の燈——がいます。エフライム、聖なる霊の琴——日々、恵みの水の流れをもって、シリアの民を潤す人。ヨハネ（クリュソストモス）とアッティコス（コンスタンティノポリスの）——真理の力強い告げ知らせ手たち。そして、これらの中で最も古い人たち、イグナティオス、ポリュカルポス、エイレナイオス、ユスティノス、ヒッポリュトス。そのうちの大部分の人たちは、主教たちの中で輝くばかりでなく、致命者たちの群れをも飾っています。',
}

def build_quotes():
    frags = {}
    fails = []
    for n in range(1, 96):
        spec = MANUAL.get(n)
        if not spec:
            key = str(n)
            if key not in AUTO:
                fails.append((n, 'no spec'))
                frags[n] = '<p>（未解決）</p>'
                continue
            spec = [tuple(x) for x in AUTO[key]]
        parts = []
        ok = True
        for (work, num, ps, pe, st, en) in spec:
            frag, err = extract_fragment(work, num, ps, pe, st, en)
            if frag is None:
                ok = False
                fails.append((n, f'{work}:{num} {err}'))
            else:
                parts.append(frag)
        if ok and parts:
            sep = '<p>…</p>' if (len(parts) > 1 and n in MANUAL) else ''
            frags[n] = sep.join(parts)
        else:
            frags[n] = '<p>（未解決）</p>'
    for n, text in QTEXT.items():
        frags[n] = f'<p>{text}</p>'
    return frags, fails

frags, fails = build_quotes()
ok_count = 95 - len([f for f in fails if 'not found' in str(f[1]) or 'no spec' in str(f[1]) or 'slice' in str(f[1])])
print(f'вербатим OK: {ok_count}/95 (спец-композиты и отзывы — вне проверки)')

body = (BODY1 + BODY2)
for n, frag in frags.items():
    body = body.replace('{{Q:%d}}' % n, '<blockquote>' + frag + '</blockquote>')
left = re.findall(r'\{\{Q:\d+\}\}', body)
assert not left, f'остались плейсхолдеры: {left}'

cyr = re.findall(r'[\u0400-\u04FF]', body)
assert not cyr, f'кириллица: {cyr[:10]}'
for tag in ('p', 'blockquote', 'h2', 'h3', 'a'):
    o = len(re.findall(f'<{tag}[ >]', body)); c = len(re.findall(f'</{tag}>', body))
    assert o == c, (tag, o, c)

refs = (
    '<p>翻訳原則：本ページは本サイトのロシア語版ページからの翻訳です。ユスティノスの著作からの引用は、'
    'すべて本サイトの日本語訳（『弁明書 第一』『弁明書 第二』『ユダヤ人トリュフォンとの対話』）によるもので、'
    '該当箇所のリンクを付けました。テルトゥリアヌス、メトディオス、エピファニオス、ヒエロニムス、テオドレトスの言葉は、'
    'ロシア語訳を参照して訳しました（本サイトにこれらの日本語訳はありません）。'
    '「使徒たちの記録」という呼び方は、ユスティノスが福音書に与えた名前です。'
    '人名は本サイトの日本語訳の伝統に従います：ユスティノス（哲学者）、トリュフォン、ポンティウス・ピラトゥス、'
    'アントニヌス・ピウス、マルクス・アウレリウス、クレセンセス、エウセビオス（カイサリアの）。</p>'
    '<p>翻訳：ロジオン・ヴラソフ（AIツールを併用）。</p>'
)

build(
    src='Иустин_Философ_мученик',
    path='Ju2A_ユスティノス2世紀',
    title='ユスティノス（哲学者）、2世紀',
    title_sub='致命者（〜100-165）、哲学者',
    meta_desc='2世紀のキリスト教護教家、ユスティノス（哲学者、致命者）の生涯と信仰：ロゴスの教え、三一の神、'
              'モーセの律法の意味、洗礼と聖体、復活と終末、そして古代の教父たちの証し。',
    menu={'parent': '2世紀', 'title': 'ユスティノス（哲学者）、致命者（〜100-165）',
          'priority': 2, 'replace': '哲学者ユスティノス殉教者（～100-165）'},
    body=body,
    refs=refs,
    out_name='ju_00_author.yml',
    update=True,
    builder='ju_author.py',
)
print(f'failures: {len(fails)}')
for n, msg in fails:
    print(f'  Q{n}: {msg}')
