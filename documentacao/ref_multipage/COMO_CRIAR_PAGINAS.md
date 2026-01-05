# Guia de Criação de Páginas (Multipage Reference)

Esta pasta contém os arquivos essenciais e instruções para replicar a estrutura
de navegação e layout multipágina utilizada no projeto.

## Arquivos de Referência

Aqui você encontra cópias dos componentes originais para fácil consulta e
reutilização em outros projetos:

1. **`FullPageMenu.vue`**: O componente de menu lateral deslizante (overlay).
2. **`layout_manager.vue`**: O layout padrão para páginas de gerenciamento
   (Dashboard), contendo cabeçalho e slots para sidebar.
3. **`page_inicio.vue`**: Exemplo de página inicial (Landing) que invoca o
   `FullPageMenu`.
4. **`page_infraestrutura.vue`**: Exemplo de página interna complexa que utiliza
   o `layout_manager`.
5. **`store_app.ts`**: Store Pinia necessária para gerenciar estado do menu,
   usuário e permissões (`ROLES`).

---

## 1. Configurando a Navegação (Menu)

O componente central é o `FullPageMenu.vue`.

### Dependências

- **Pinia Store (`useAppStore`)**: Gerencia o estado `isMenuOpen` e as
  permissões (`ROLES`).
- **Supabase**: Para logout e dados do usuário.
- **Tailwind CSS**: Estilização baseada em tokens (`bg-background`,
  `text-primary`, etc.).

### Como Usar

Em uma página "Landing" (como `page_inicio.vue`), você importa e utiliza o menu
assim:

```vue
<script setup>
const menuAberto = ref(false)
const toggleMenu = () => menuAberto.value = !menuAberto.value
</script>

<template>
  <button @click="toggleMenu">Abrir Menu</button>
  
  <FullPageMenu 
    :is-open="menuAberto" 
    @close="toggleMenu"
  />
</template>
```

> **Nota:** No `FullPageMenu.vue`, as rotas são definidas manualmente na função
> `handleNavigation` e no template via `@click="handleNavigation('/rota')"`. Ao
> levar para outro projeto, atualize os caminhos.

---

## 2. Padrão de Página Interna (Layout Manager)

Para páginas administrativas (como Infraestrutura, Educacional), usamos o
`layouts/manager.vue`.

### Estrutura do Layout

Este layout fornece:

- **Header Unificado**: Com título, subtítulo e ícone da seção.
- **Tabs de Navegação**: Para alternar entre sub-módulos (ex: Escolas, Prédios).
- **Sidebar Slot**: Área lateral para filtros, resumo ou dashboard rápido.
- **Conteúdo Principal**: Área central com scroll independente.

### Implementação (ver `page_infraestrutura.vue`)

No seu arquivo de página (`pages/minha-pagina.vue`):

```vue
<script setup>
definePageMeta({
  layout: false // Desativa o layout padrão para usar o <NuxtLayout name="manager">
})
// ... lógica da página
</script>

<template>
  <NuxtLayout name="manager">
    <!-- Slot: Ícone do Módulo -->
    <template #header-icon>
       <svg>...</svg>
    </template>

    <!-- Slot: Título -->
    <template #header-title>Minha Página</template>

    <!-- Slot: Subtítulo/Stats -->
    <template #header-subtitle>Gestão de Itens</template>

    <!-- Slot: Ações (Botão Novo, Busca) -->
    <template #header-actions>
       <button>Novo Item</button>
    </template>

    <!-- Slot: Sidebar (Opcional) -->
    <template #sidebar>
       <MeuDashboardLateral />
    </template>

    <!-- Conteúdo Principal -->
    <div>
       <!-- Lista de itens, tabelas, etc -->
    </div>

  </NuxtLayout>
</template>
```

---

## 3. Gerenciamento de Estado (Store)

O arquivo `store_app.ts` define:

- `isMenuOpen`: Controla visibilidade (se usado globalmente).
- `user`, `role`, `company`: Contexto do usuário logado.
- `ROLES`: Constante exportada para verificar permissões (ex:
  `hasAccess([ROLES.ADMIN])`).

Certifique-se de ter o Pinia instalado e configurado no `nuxt.config.ts`.

## Checklist para Migração

Ao levar este módulo para outro projeto:

1. [ ] Copiar `FullPageMenu.vue` para `components/`.
2. [ ] Copiar `layout_manager.vue` para `layouts/manager.vue`.
3. [ ] Copiar/Adaptar `store_app.ts` para `stores/app.ts`.
4. [ ] Garantir que Icons (SVG) ou biblioteca de ícones estejam disponíveis.
5. [ ] Configurar as rotas no `FullPageMenu.vue` para bater com as páginas do
       novo projeto.
