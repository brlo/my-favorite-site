import { test } from 'node:test'
import assert from 'node:assert/strict'
import { needsFullSkeleton } from '../src/lib/skeleton.js'

test('needsFullSkeleton: старая дельта и новый сервер', () => {
  // старая установка, сервер уже умеет новые поля
  assert.equal(needsFullSkeleton({ since: 100, localVersion: 0, serverVersion: 2 }), true)
  // сервер без версии — полный скелет новых полей не даст
  assert.equal(needsFullSkeleton({ since: 100, localVersion: 0, serverVersion: 1 }), false)
  // уже перечитали
  assert.equal(needsFullSkeleton({ since: 100, localVersion: 2, serverVersion: 2 }), false)
  // сервер новее клиента
  assert.equal(needsFullSkeleton({ since: 100, localVersion: 2, serverVersion: 3 }), true)
})

test('needsFullSkeleton: первый запуск и принудительный полный скелет', () => {
  assert.equal(needsFullSkeleton({ since: 0, localVersion: 0, serverVersion: 2 }), false)
  assert.equal(needsFullSkeleton({ since: 100, localVersion: 0, serverVersion: 2, forceFull: true }), false)
})
