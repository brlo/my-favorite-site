import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import * as path from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  // docs https://vitejs.dev/config/server-options.html
  server: {
    port: 5173,
    strictPort: true, // не искать следующий свободный порт, а выходить, если занято
  },
  plugins: [vue()],
  resolve: {
    alias: {
      '@' : path.resolve(__dirname, './src')
    }
  }
})
// {
//   "scripts": {
//     "dev": "vite", // start dev server, aliases: `vite dev`, `vite serve`
//     "build": "vite build", // build for production
//     "preview": "vite preview" // locally preview production build
//   }
// }
