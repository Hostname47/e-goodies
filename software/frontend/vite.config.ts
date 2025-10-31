import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  
  // Development server configuration
  server: {
    host: true, // Listen on all addresses (important for Docker)
    port: 5173, // Development port
    strictPort: true, // Fail if port is already in use
    
    // File watching (important for some Docker setups)
    watch: {
      usePolling: true,
    },
    
    // Proxy API requests during development
    proxy: {
      '/api': {
        target: 'http://localhost:8080', // Your Symfony API container
        changeOrigin: true,
        secure: false,
      }
    }
  },
  
  // Production build configuration
  build: {
    outDir: 'dist', // Output directory
    sourcemap: false, // Disable sourcemaps in production
    minify: 'esbuild', // Fast minification
  },
  
  // Preview server (for testing production build locally)
  preview: {
    port: 5173,
    host: true,
  }
})