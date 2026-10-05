// sql.js для браузерной версии (только для разработки). Берём ту же версию, что использует jeep-sqlite.
const fs = require('fs')
const path = require('path')
const jeepDir = path.dirname(require.resolve('jeep-sqlite/package.json'))
const wasm = require.resolve('sql.js/dist/sql-wasm.wasm', { paths: [jeepDir] })
fs.mkdirSync(path.join(__dirname, '..', 'public', 'assets'), { recursive: true })
fs.copyFileSync(wasm, path.join(__dirname, '..', 'public', 'assets', 'sql-wasm.wasm'))
