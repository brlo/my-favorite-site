import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { readFileSync } from 'node:fs'

const pkg = JSON.parse(readFileSync(new URL('./package.json', import.meta.url), 'utf8'))

// В разработке API и статика проксируются на локальный Rails (docker, порт 80).
const backend = process.env.BACKEND || 'http://localhost'

export default defineConfig({
  base: './',
  define: { __APP_VERSION__: JSON.stringify(pkg.version) },
  plugins: [vue({ template: { compilerOptions: { isCustomElement: (tag) => tag === 'jeep-sqlite' } } })],
  server: {
    port: 5174,
    proxy: {
      '/api/': { target: backend, changeOrigin: true },
      '^/s/': { target: backend, changeOrigin: true },
    },
  },
  build: { target: 'es2020', chunkSizeWarningLimit: 2000 },
})
