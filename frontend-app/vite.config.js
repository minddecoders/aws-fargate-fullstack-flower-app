import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite' // 1. Import Tailwind

// https://vite.dev
export default defineConfig({
  plugins: [
    react(),
    tailwindcss(), // 2. Add Tailwind to your plugins array
  ],
})
