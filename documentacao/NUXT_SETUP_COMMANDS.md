# Receita Completa de Setup Nuxt 4 (The Holy Grail)

Este guia cobre todo o processo de criação, do zero absoluto até o servidor rodando, seguindo suas preferências (Minimal, Sem Git automático, Sem Install automático).

## 1. Inicializar o Projeto

Abra o terminal na pasta onde você quer que a pasta do projeto seja criada (ex: `d:\NUXT\sped_nuxt`).

```powershell
npx nuxi@latest init front_end
```

**Responda às perguntas do CLI:**
1.  **Which template would you like to use?**
    *   Escolha: `[ ] Minimal` (Use as setas e Enter)
2.  **Initialize git repository?**
    *   Escolha: `No`
3.  **Install dependencies with npm?**
    *   Escolha: `No`

---

## 2. Instalação de Dependências

Entre na pasta criada e instale as dependências base e os módulos (Tailwind, Pinia, Supabase).

```powershell
cd front_end

# 1. Instalar dependências base do Nuxt
npm install

# 2. Instalar Módulos (Tailwind, Pinia + Core, Supabase)
npm install -D @nuxtjs/tailwindcss @pinia/nuxt pinia @nuxtjs/supabase
```

---

## 3. Criar Estrutura de Pastas (Padrão Nuxt 4) e .env

Rode este bloco de comandos no terminal (dentro da pasta `front_end`) para criar toda a árvore de diretórios e o arquivo de ambiente.

```powershell
# Criar pastas principais do Nuxt dentro de 'app'
mkdir app/pages -Force
mkdir app/layouts -Force
mkdir app/components -Force
mkdir app/composables -Force
mkdir app/plugins -Force
mkdir app/utils -Force
mkdir app/middleware -Force
mkdir app/assets -Force

# Public FICA NA RAIZ
mkdir public -Force

# Criar pastas do servidor (server engine)
mkdir server/api -Force
mkdir server/routes -Force
mkdir server/middleware -Force
mkdir server/plugins -Force
mkdir server/utils -Force

# Novas pastas recomendadas (Shared & Modules)
mkdir shared -Force
mkdir modules -Force

# Criar arquivo .env vazio (se não existir)
if (-not (Test-Path .env)) { New-Item .env -ItemType File }

echo "Estrutura criada!"
```

### Configurar `.env`

Abra o arquivo `.env` criado na raiz `front_end/` e cole suas chaves:

```env
# Supabase Configuration
SUPABASE_URL="https://sua-url-do-projeto.supabase.co"
SUPABASE_KEY="sua-chave-anon-publica-aqui"
```

---

## 4. Configurar `nuxt.config.ts`

Substitua todo o conteúdo do arquivo `front_end/nuxt.config.ts` pelo código abaixo:

```typescript
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
```

---

## 5. Finalizar e Rodar

Agora que tudo está configurado, prepare o ambiente e rode o servidor.

```powershell
# Gerar tipos e arquivos virtuais do Nuxt
npx nuxi prepare

# Rodar o servidor de desenvolvimento
npm run dev
```

Acesse `http://localhost:3000` 🚀
