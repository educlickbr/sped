# Solução Definitiva para FOUC em Nuxt 3/4

Este documento descreve a estratégia **"Nitro Critical Injector"** utilizada para eliminar completamente o Flash of Unstyled Content (FOUC), especialmente em modo de desenvolvimento (Vite), onde os estilos são injetados de forma assíncrona.

## O Problema
No Nuxt em modo dev, o servidor envia o HTML bruto. O CSS só é injetado pelo Vite via JavaScript após alguns milissegundos. Durante esse intervalo, o navegador renderiza a página sem estilos (fundo branco, fontes padrão, formulários desalinhados), o que causa um "flash" desagradável antes do loader ou do conteúdo estilizado aparecer.

## A Solução: Nitro Critical Injector

A estratégia consiste em três camadas de defesa:

### 1. Esconder o App no Servidor (`nuxt.config.ts`)
Forçamos o container principal do Nuxt (`#__nuxt`) a ser invisível no nível do `<head>`. Isso garante que o navegador saiba que não deve renderizar o conteúdo do app antes mesmo de terminar de baixar o HTML.

```typescript
// nuxt.config.ts
export default defineNuxtConfig({
  app: {
    head: {
      style: [
        { 
          innerHTML: 'html, body { background-color: #0a0a0c !important; color: white; margin: 0; } #__nuxt { display: none; }' 
        }
      ]
    }
  }
})
```

### 2. Injetar o Loader via Nitro (`server/plugins/loader.ts`)
Usamos um plugin do Nitro para injetar o HTML e CSS do loader diretamente na resposta do servidor, **fora** do container `# __nuxt`. Isso faz com que o loader seja a primeira e única coisa que o navegador renderiza.

```typescript
// server/plugins/loader.ts
export default defineNitroPlugin((nitroApp) => {
  nitroApp.hooks.hook('render:html', (html) => {
    const loaderHtml = `
      <div id="nitro-initial-loader" style="position: fixed; inset: 0; z-index: 9999; background-color: #0c0c0c; ...">
        <!-- Ícone e texto do loader -->
      </div>
    `
    html.bodyPrepend.push(loaderHtml)
  })
})
```

### 3. Handover no Cliente (`app.vue`)
Quando o Vue é montado e hidratado (`onMounted`), fazemos a transição: revelamos o container `# __nuxt` e removemos o loader do Nitro.

```typescript
// app.vue
onMounted(() => {
  // 1. Revela o app
  const nuxtContainer = document.getElementById('__nuxt')
  if (nuxtContainer) nuxtContainer.style.display = 'block'

  // 2. Remove o loader do servidor com fade
  const nitroLoader = document.getElementById('nitro-initial-loader')
  if (nitroLoader) {
    nitroLoader.style.opacity = '0'
    setTimeout(() => nitroLoader.remove(), 500)
  }
})
```

## Por que funciona?
- **Imediato**: O estilo no `head` e o HTML do loader no `bodyPrepend` são as primeiras coisas processadas pelo parser de HTML do navegador.
- **Independente**: Não depende do carregamento de arquivos `.js` ou `.css` externos.
- **Universal**: Resolve tanto a primeira carga (F5) quanto o estado de hidratação.

Essa técnica pode ser replicada em qualquer projeto Nuxt que exija uma experiência de carregamento "premium" e sem artefatos visuais.
