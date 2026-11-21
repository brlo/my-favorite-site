# -*- coding: utf-8 -*-
"""Цитаты-отзывы (Q96-Q101): дословная вырезка из EN-страниц отцов + свои переводы."""
import re, html, os

HERE = os.path.dirname(os.path.abspath(__file__))
SEP = '<p>&lt;…&gt;</p>'


def plain(fn):
    h = open(os.path.join(HERE, fn), encoding='utf-8').read()
    t = re.sub(r'</?(p|h2|h3|blockquote|div|br|li)\b[^>]*>', ' ', h)
    t = html.unescape(re.sub(r'<[^>]+>', '', t))
    t = re.sub(r'\[\d+\]', ' ', t)
    return re.sub(r'\s+', ' ', t).strip()


def cut(fn, start, end):
    t = plain(fn)
    i = t.find(start)
    assert i >= 0, (fn, start)
    j = t.find(end, i)
    assert j >= 0, (fn, end)
    return t[i:j + len(end)]


def mark(text, phrases):
    """phrases: [(tag, phrase)] — обернуть, требуя уникальности."""
    for tag, ph in phrases:
        n = text.count(ph)
        assert n == 1, f'{ph[:40]!r}: вхождений {n}'
        text = text.replace(ph, f'<{tag}>{ph}</{tag}>')
    return text


def esc_for_body(t):
    # только & < > — остальное (æ, кавычки) как есть
    return t.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


REVIEW = {
    96: {
        'where': 'tertullian-against-the-valentinians (Against the Valentinians, V)',
        'groups': [
            [(('rev_tertullian-against-the-valentinians.html',
               'Nor shall we hear it said of us from any quarter',
               'even as in this particular one.'),
              [('strong', 'eminently holy and excellent men'),
               ('strong', 'Justin, philosopher and martyr')])],
        ],
    },
    97: {
        'where': 'methodius-from-the-discourse-on-the-resurrection (On the Resurrection, VI)',
        'groups': [
            [(('rev_methodius-from-the-discourse-on-the-resurrection.html',
               'Now Justin of Neapolis',
               'the kingdom of heaven lives.'),
              [('strong', 'not far removed'),
               ('strong', 'from the virtues of the apostles')])],
        ],
    },
    99: {
        'where': 'jerome-the-perpetual-virginity-of-blessed-mary (Against Helvidius, 19)',
        'groups': [
            [(('rev_jerome-the-perpetual-virginity-of-blessed-mary.html',
               'Now that I have cleared the rocks and shoals',
               'extend my book to an undue length.'),
              [('strong', 'Tertullian as a witness'),
               ('strong', 'he did not belong to the Church'),
               ('strong', 'the whole series of ancient writers? Ignatius, Polycarp, Irenæus, '
                          'Justin Martyr, and many other apostolic and eloquent men'),
               ('strong', 'wrote volumes replete with wisdom. If you had ever read what they '
                          'wrote, you would be a wiser man')])],
        ],
    },


}

# --- свои переводы (Q98, Q101): EN-изданий на сайте нет
OWN = {
    98: {
        'where': 'Epiphanius, Panarion (translated from the Russian)',
        'groups': [
            ['13. Tatianists. Tatian was a contemporary of the <strong>holy martyr and '
             'philosopher Justin</strong>. And after the death of the martyr and philosopher '
             'Justin, having become a disciple of Marcion, he was corrupted by his doctrines '
             'and taught the same as he, adding other things besides Marcion. It was said '
             'that he came from Mesopotamia.'],
            ['Then a certain Tatian rose up as their successor, either having lived in their '
             'own times or having presented his vain teaching after them. At first, as one '
             'who came from the Greeks and possessed a Greek education, he was a '
             'contemporary of <strong>Justin the Philosopher, a holy man and a friend of '
             'God</strong>, who believed in Christ from among the Samaritans. For this '
             'Justin was a Samaritan by birth, believed in Christ, <strong>performed great '
             'deeds, showed forth a virtuous life, and at last, having accepted martyrdom '
             'for Christ</strong> from the Romans under the governor Rusticus and the '
             'emperor Hadrian, <strong>was deemed worthy of the perfect crown</strong> in '
             'the flower of his age, namely at thirty years. Having been his contemporary, '
             'the aforementioned Tatian at first had a good disposition and a sound faith, '
             'while he was with <strong>the holy martyr Justin</strong>. But when Saint '
             'Justin had died, what happened to Tatian was like what happens to a blind man '
             'who, if the guide who led him before leaves him, then, when he comes to a '
             'precipice, in his blindness rushes down irresistibly until he falls to death, '
             '&lt;…&gt; [he departed] after the death of Saint Justin to the eastern lands, and during his '
             'stay there he fell into evil opinions, and began, in accordance with the tales '
             'of Valentinus, to introduce certain aeons and certain principles and heavenly '
             'offspring.'],
        ],
    },
    101: {
        'where': 'Theodoret of Cyrus, Letters (translated from the Russian)',
        'groups': [
            ['Which of the <strong>holy fathers</strong> did not proclaim this same '
             'teaching?! &lt;…&gt;',
             'And his teacher Alexander fought for these <strong>dogmas [about God]</strong>. '
             'Such also were Eustathius, Meletius, Flavian, the lamps of the East, Ephrem, '
             'the lyre of the Holy Spirit, who daily waters the Syrian people with streams '
             'of grace, John (Chrysostom) and Atticus (of Constantinople), the '
             '<strong>loud-voiced preachers of the truth</strong> and, older than these, '
             'Ignatius, Polycarp, Irenaeus, <strong>Justin</strong> and Hippolytus, of whom '
             'the greater part not only shines in the ranks of the hierarchs, but also <strong>adorns '
             'the choir of martyrs</strong>.'],
        ],
    },
}


def flat(groups):
    paras = []
    for i, g in enumerate(groups):
        if i:
            paras.append(SEP)
        paras.extend(g)
    return paras


def build_q100():
    t1 = cut('rev_de_viris.html', 'Justin, a philosopher', 'the ignominy of the cross.')
    t2 = 'At last, ' + cut('rev_de_viris.html', 'accused of being a Christian, through the efforts',
                           'he shed his blood for Christ.')
    t = t1 + ' &lt;…&gt; ' + t2
    t = mark(t, [('strong', 'Justin'),
                 ('strong', 'laboured strenuously in behalf of the religion of Christ'),
                 ('strong', 'he shed his blood for Christ')])
    return '<p>' + t + '</p>'


def build():
    out = {}
    for q, spec in REVIEW.items():
        groups = []
        for g in spec['groups']:
            paras = []
            for item in g:
                (fn, start, end), phrases = item[0], item[1]
                prefix = item[2] if len(item) > 2 else ''
                t = prefix + cut(fn, start, end)
                t = mark(t, phrases)
                paras.append('<p>' + esc_for_body_keep_tags(t) + '</p>')
            groups.append(paras)
        out[q] = {'quote': flat(groups), 'where': spec['where']}
    out[100] = {'quote': [build_q100()], 'where': 'De_Viris_Illustribus (23)'}
    for q, spec in OWN.items():
        groups = [['<p>' + p + '</p>' for p in g] for g in spec['groups']]
        out[q] = {'quote': flat(groups), 'where': spec['where'], 'own': True}
    return out


def esc_for_body_keep_tags(t):
    """экранировать только & (кроме уже готовых тегов) — в текстах ANF их нет"""
    return t


if __name__ == '__main__':
    import json
    d = build()
    for q in sorted(d):
        print(f'--- Q{q} [{d[q]["where"]}]')
        for g in d[q]['groups']:
            for p in g:
                print(p)
        print()
