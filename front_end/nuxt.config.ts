export default defineNuxtConfig({
  // 1. Registro de Módulos (A tríade sagrada)
  app: {
    head: {
      style: [
        { innerHTML: 'html, body { background-color: #0a0a0c !important; color: white; margin: 0; padding: 0; } #__nuxt { display: none; }' }
      ]
    }
  },
  modules: [
    "@nuxtjs/tailwindcss",
    "@pinia/nuxt",
    "@nuxtjs/supabase",
  ],

  // CSS Global (Variáveis CSS, Reset, Fontes)
  css: ["./app/assets/css/style.css"],

  // 2. Configuração do Supabase (Segurança JWT)
  supabase: {
    redirectOptions: {
      login: "/login", // Onde mandar o usuário se não estiver logado
      callback: "/confirm", // Para onde o Supabase volta após login social
      exclude: ["/", "/teste-tailwind", "/processo_seletivo", "/processo_seletivo/*", "/recuperar_senha", "/trocar_senha", "/mensagem"], // Páginas públicas
    },
  },

  // 3. Pinia Auto-imports (Para você não precisar importar 'defineStore' toda vez)
  pinia: {
    storesDirs: ["./stores/**"],
  },

  devtools: { enabled: true },
});
