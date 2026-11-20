import { test } from 'node:test'
import assert from 'node:assert/strict'
import { hexToRgb, overlayStyle, overlayTextColor, overlayTitleClass } from '../src/lib/cover.js'

test('hexToRgb: короткая и полная запись', () => {
  assert.deepEqual(hexToRgb('#123456'), [0x12, 0x34, 0x56])
  assert.deepEqual(hexToRgb('#abc'), [0xaa, 0xbb, 0xcc])
  assert.equal(hexToRgb('red'), null)
  assert.equal(hexToRgb(null), null)
})

test('overlayStyle: градиент из цвета подложки', () => {
  assert.equal(
    overlayStyle('#123456').background,
    'linear-gradient(to top, rgba(18, 52, 86, 0.85) 0%, rgba(18, 52, 86, 0) 60%)'
  )
  assert.equal(overlayStyle(''), null)
})

test('overlayTextColor: некорректный цвет заменяется на белый', () => {
  assert.equal(overlayTextColor('#abcdef'), '#abcdef')
  assert.equal(overlayTextColor(''), '#ffffff')
  assert.equal(overlayTextColor('black'), '#ffffff')
})

test('overlayTitleClass: пороги как на сайте', () => {
  assert.equal(overlayTitleClass('Короткий заголовок'), '')
  assert.equal(overlayTitleClass('Заголовок длиной больше двадцати пяти символов'), 'title-md')
  assert.equal(overlayTitleClass('Очень длинный заголовок '.repeat(3)), 'title-lg')
})
