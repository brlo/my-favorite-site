import { test } from 'node:test'
import assert from 'node:assert/strict'
import { norm, ftsQuery, stripTags, htmlToParagraphs, highlightText, queryTerms, rubyfy, snippet } from '../src/lib/text.js'
import { parseHref } from '../src/lib/links.js'

test('norm: регистр, диакритика, пунктуация', () => {
  assert.equal(norm('В нача́ле сотвори́ Бог небо и землю.'), 'в начале сотвори бог небо и землю')
  assert.equal(norm('Ёлка, «ёж»!'), 'елка еж')
  assert.equal(norm('Ἐν ἀρχῇ ἐποίησεν ὁ θεὸς'), 'εν αρχη εποιησεν ο θεος')
  assert.equal(norm('בְּרֵאשִׁית בָּרָא'), 'בראשית ברא')
  assert.equal(norm('Въ нача́лѣ сотворѝ бг҃ъ'), 'въ началѣ сотвори бгъ')
})

test('norm: иероглифы по одному, кана с дакутэном сохраняется', () => {
  assert.equal(norm('初めに神が'), '初 め に 神 が')
  assert.equal(norm('起初，神创造天地。'), '起 初 神 创 造 天 地')
})

test('ftsQuery: префиксы и фразы', () => {
  assert.equal(ftsQuery('Сотвори Бог'), 'сотвори* бог*')
  assert.equal(ftsQuery('и Бог', { exact: true }), '"и бог"')
  assert.equal(ftsQuery('神創造'), '"神 創 造"')
  assert.equal(ftsQuery('  ,. '), null)
})

test('stripTags: теги, сущности, фуригана', () => {
  assert.equal(stripTags('<j>Я есмь</j>&nbsp;путь').replace(/\s+/g, ' ').trim(), 'Я есмь путь')
  assert.equal(stripTags('<ruby><rb>私</rb><rt>わたし</rt></ruby>は'), '私は')
  assert.equal(stripTags('сло<i>во</i><p>да</p>'), 'слово да ')
  assert.equal(stripTags('私[わたし]は'), '私は')
})

test('htmlToParagraphs', () => {
  const html = '<h2>Глава</h2><p>Первый&nbsp;абзац</p><ul><li>пункт</li></ul><p>a</p><p>Второй<br>строка</p>'
  assert.deepEqual(htmlToParagraphs(html), ['Глава', 'Первый абзац', 'пункт', 'Второй', 'строка'])
})

test('highlightText: подсветка по началу слова, экранирование', () => {
  const terms = queryTerms('бог')
  assert.equal(highlightText('И сказал Бог: <да>', terms), 'И сказал <mark>Бог</mark>: &lt;да&gt;')
  assert.equal(highlightText('Богу и богам', queryTerms('бог')), '<mark>Богу</mark> и <mark>богам</mark>')
  assert.equal(highlightText('初めに神が', queryTerms('神')), '初めに<mark>神</mark>が')
})

test('snippet обрезает вокруг совпадения', () => {
  const long = 'а '.repeat(300) + 'искомое' + ' б'.repeat(300)
  const s = snippet(long, queryTerms('искомое'), 20)
  assert.ok(s.includes('искомое'))
  assert.ok(s.startsWith('…') && s.endsWith('…'))
})

test('rubyfy', () => {
  assert.equal(rubyfy('私[わたし]は'), '<ruby><rb>私</rb><rt>わたし</rt></ruby>は')
})

test('parseHref: ссылки сайта', () => {
  const books = { gen: {}, mf: {}, ps: {} }
  assert.deepEqual(parseHref('#cite_note-1', books), { type: 'anchor', id: 'cite_note-1' })
  assert.deepEqual(parseHref('/ru/gen/10/#L8', books), { type: 'bible', tr: 'ru', book: 'gen', chapter: 10, verse: 8 })
  assert.deepEqual(parseHref('https://bibleox.com/ru/csl-ru/ps/49/#L7', books), { type: 'bible', tr: 'csl-ru', book: 'ps', chapter: 49, verse: 7 })
  assert.deepEqual(parseHref('https://bibleox.com/en/gr-ru/mf/8', books), { type: 'bible', tr: 'ru', book: 'mf', chapter: 8, verse: null })
  assert.deepEqual(parseHref('https://bibleox.com/ru/ru/w/%D0%A6%D0%B5%D1%80%D0%BA%D0%BE%D0%B2%D1%8C', books), { type: 'page', lang: 'ru', path: 'Церковь', hash: null })
  assert.deepEqual(parseHref('/ru/ru/w/abc#HH-1', books), { type: 'page', lang: 'ru', path: 'abc', hash: 'HH-1' })
  assert.equal(parseHref('https://azbyka.ru/otechnik/x', books).type, 'external')
  assert.equal(parseHref('mailto:a@b.c', books).type, 'external')
})
