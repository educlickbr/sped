export default defineNuxtConfig({
  // 1. Registro de Módulos (A tríade sagrada)
  modules: [
    '@nuxtjs/tailwindcss',
    '@pinia/nuxt',
    '@nuxtjs/supabase'
  ],

  // 2. Configuração do Supabase (Segurança JWT)
  supabase: {
    redirectOptions: {
      login: '/login',      // Onde mandar o usuário se não estiver logado
      callback: '/confirm', // Para onde o Supabase volta após login social
      exclude: ['/'],      // Páginas públicas (ex: Landing Page)
    }
  },

  // 3. Pinia Auto-imports (Para você não precisar importar 'defineStore' toda vez)
  pinia: {
    storesDirs: ['./stores/**'],
  },

  devtools: { enabled: true }
})