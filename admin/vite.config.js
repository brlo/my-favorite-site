import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import * as path from 'path'

// https://vitejs.dev/config/
export default defineConfig({
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
