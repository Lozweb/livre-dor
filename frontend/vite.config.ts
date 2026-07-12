import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': {
        target: process.env['VITE_API_TARGET'] ?? 'http://192.168.1.42',
        changeOrigin: true,
      },
    },
  },
})
