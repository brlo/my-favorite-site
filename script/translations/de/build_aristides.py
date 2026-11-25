#!/usr/bin/env python3
"""Сборка немецкого Аристида Афинского: автор + «Апология» (BKV 1913)."""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
DB = os.path.join(ROOT, 'db', 'translations', 'de')
SRC = os.path.join(ROOT, 'tmp', 'de_bkv', 'out', 'arist.html')

AUTHOR = (
    '<h2>Biographie</h2>'
    '<p>Gedenktag: 31. August (13. September) (griech.)</p>'
    '<p>Über das Leben und die Persönlichkeit dieses Apologeten ist sehr wenig bekannt. '
    'Der selige Hieronymus nennt ihn „einen der beredtesten athenischen Philosophen“ '
    '(„Über berühmte Männer“, 20), Eusebius „einen festen Anhänger unseres Glaubens“ '
    '(„Kirchengeschichte“, IV, 3, 3). Eusebius berichtet auch, dass Aristides seine Apologie '
    'dem Kaiser Hadrian übergab, und präzisiert in der Chronik auch das Jahr – 125. Nach dem '
    'Zeugnis des Eusebius wurde dieses Werk damals „bei vielen aufbewahrt“. Es sind '
    'Martyrologien des Märtyrers Aristides bekannt.</p>'
    '<p>Eusebius erwähnt auch einen anderen Aristides, den man nicht mit dem athenischen '
    'Apologeten verwechseln darf. An ihn richtete Julius Africanus (um 160–237) einen Brief '
    'über die Harmonisierung der evangelischen Geschlechtsregister Christi („Kirchengeschichte“, '
    'I, 7; VI, 31).</p>'
    '<p>Die Apologie des Aristides galt lange als verloren. Doch 1878 wurde in einer Handschrift '
    'des 10. Jahrhunderts ein armenischer Auszug aus diesem Werk entdeckt. Daraufhin fand 1889 '
    'Rendel Harris (J. R. Harris) im Katharinenkloster auf dem Sinai den syrischen Text der '
    'vollständigen Fassung der Apologie des Aristides. Schließlich machte Robinson (A. Robinson) '
    'die Entdeckung, dass der Text der Apologie Bestandteil des bekannten Werkes des 7. '
    'Jahrhunderts „Leben des Barlaam und Joasaph“ ist, und zwar als Rede des Einsiedlers Nachor '
    'an König Abenner.</p>'
    '<p>Die gefundenen Texte ermöglichten neue Urteile über die Abfassungszeit der Apologie. '
    'Der syrische Text hat zwei Überschriften: die erste – „Apologie, die der athenische '
    'Philosoph Aristides vor dem Kaiser Hadrian über die Verehrung des allmächtigen Gottes hielt“, '
    'und die zweite – „An den Kaiser Titus Hadrian Antoninus, Augustus und Pius, von Marcianus '
    'Aristides, dem Philosophen aus Athen“.</p>'
    '<p>Kaiser Antoninus, der nach seiner Adoption durch Kaiser Hadrian den Beinamen Titus Aelius '
    'Hadrian erhielt und Pius genannt wurde, regierte von 138 bis 161. In diese Zeit setzen die '
    'Abfassung der Apologie Harris, Bardenhewer (O. Bardenhewer), Harnack (A. Harnack) und '
    'I. W. Popow. Das Abfassungsdatum lässt sich in diesem Fall durch folgende Umstände '
    'präzisieren. Erstens wird in der Anrede Marc Aurel nicht erwähnt, der 147 Mitregent des '
    'Antoninus Pius wurde. Zweitens beklagt der Märtyrer Aristides zwar Verleumdungen gegen die '
    'Christen, spricht aber nicht von Verfolgungen, was auf den Beginn der Regierung des '
    'Antoninus hinweist. Und schließlich muss die Apologie des Aristides früher als die Erste '
    'Apologie des Märtyrers Justin geschrieben sein, da sie theologisch weniger entwickelt ist '
    'und keinen Einfluss von dieser zeigt.</p>'
    '<p>Die armenische Handschrift mit der Apologie enthält auch den Text der Homilie „Über die '
    'Anrufung des Räubers und die Antwort des Gekreuzigten an ihn“. Die Zugehörigkeit dieser '
    'Homilie zum Märtyrer Aristides wird bestritten wegen Ausdrücke und Wendungen, die für die '
    'antinestorianische Polemik charakteristisch sind, sowie wegen des Fehlens von Hinweisen '
    'antiker Schriftsteller auf die Autorschaft des Aristides. Mit dem Namen des Aristides ist '
    'auch ein Auszug von einigen Zeilen aus dem sogenannten „Brief des Aristides an alle '
    'Philosophen“ verbunden. Dieses Zitat befindet sich in einer antinestorianischen Florilegie '
    '(Sammlung von Zitaten aus den Schriften der Väter und Lehrer der Kirche) und ist '
    'wahrscheinlich eine freie Wiedergabe eines Gedankens aus der Apologie des Aristides.</p>'
)

SOURCE = (
    '<hr><p><strong>Quelle:</strong> Übersetzung von Dr. Kaspar Julius, '
    '<em>Apologie</em> (Bibliothek der Kirchenväter, 1. Reihe, Bd. 12), München 1913. '
    'Text nach <a href="https://bkv.unifr.ch/de/works/cpg-1062/versions/apologie-bkv">bkv.unifr.ch</a>; '
    'die Anmerkungen der Ausgabe sind weggelassen.</p>'
)


def q(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'


def block(s):
    return '\n'.join('      ' + line if line else '' for line in s.split('\n'))


def main():
    body = open(SRC, encoding='utf-8').read().strip().replace('<h2>0</h2>', '')
    work = ('<p><em>Apologie, übersetzt von Dr. Kaspar Julius '
            '(Bibliothek der Kirchenväter, 1. Reihe, Bd. 12, München 1913).</em></p>'
            + body + SOURCE)
    author = f'''# Аристид Афинский: страница автора (немецкая библиотека)
# Сборка: script/translations/de/build_aristides.py

lang: de
list: "Kirchenvaeter"
pages:

  - src: "Аристид_Афинский"
    path: "Aristides_von_Athen"
    title: "Aristides von Athen, 1.–2. Jh."
    title_sub: "Philosoph, einer der ersten christlichen Apologeten."
    menu: {{ parent: "2. Jahrhundert", title: "Aristides, Heiliger, Philosoph von Athen (1.–2. Jh.)", replace: "Aristides, Heiliger, Philosoph von Athen (1.–2. Jh.)", priority: 6 }}
    update: true
    body: |-
{block(AUTHOR)}
'''
    works = f'''# Аристид Афинский: «Апология» (немецкая библиотека)
# Сборка: script/translations/de/build_aristides.py

lang: de
list: "Aristides_von_Athen"
pages:

  - src: "Аристид-апология"
    path: "Aristides_Apologie"
    title: "Apologie"
    menu: {{ title: "Apologie", priority: 1 }}
    update: true
    body: |-
{block(work)}
'''
    for name, text in (('arist_author.yml', author), ('arist_works.yml', works)):
        path = os.path.join(DB, name)
        open(path, 'w', encoding='utf-8').write(text)
        print('написан', os.path.relpath(path, ROOT), os.path.getsize(path), 'байт')


if __name__ == '__main__':
    main()
