# Padrão BFF (Backend for Frontend) e SSR com Supabase

Este documento descreve como utilizamos o Nuxt Server como camada BFF para
intermediar chamadas ao Supabase, garantindo segurança, formatação de dados e
compatibilidade com SSR (Server-Side Rendering).

## Fluxo da Arquitetura

1. **Cliente (Frontend)**: Realiza uma chamada usando `useFetch` (ou `$fetch`)
   para a rota interna `/api/*`.
2. **Servidor (Nuxt Nitro)**: Recebe a requisição, valida parâmetros de sessão e
   entrada.
3. **Supabase (`serverSupabaseClient`)**: O servidor executa a chamada RPC ou
   Query no Supabase usando o cliente autenticado do servidor.
4. **Resposta**: O servidor trata erros, formata a resposta do banco para um
   padrão amigável ao frontend e retorna o JSON.

## Arquivos de Referência

- **`server_api_infra_get.ts`**: Exemplo completo de um endpoint GET que mapeia
  múltiplos recursos ("escolas", "predios") para RPCs diferentes do banco.

---

## 1. Criando um Endpoint BFF (`server/api`)

Crie arquivos dentro de `server/api/`. Use colchetes para rotas dinâmicas, ex:
`[resource].get.ts`.

### Estrutura Padrão

```typescript
import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    // 1. Obter Parâmetros
    const query = getQuery(event);

    // 2. Inicializar Cliente Supabase (Server-Side)
    // O cookie de autenticação é passado automaticamente pelo Nuxt
    const client = await serverSupabaseClient(event);

    // 3. Validação Básica
    if (!query.id_empresa) {
        throw createError({
            statusCode: 400,
            message: "Faltando ID da empresa",
        });
    }

    // 4. Chamada ao Supabase (RPC ou Query)
    try {
        const { data, error } = await client.rpc("nome_da_funcao_rpc", {
            p_id_empresa: query.id_empresa,
            p_filtro: query.busca || null,
        });

        if (error) throw error;

        // 5. Normalização da Resposta
        // Garante que o frontend sempre receba a mesma estrutura (ex: items, total)
        return {
            items: data[0]?.itens || [],
            total: data[0]?.qtd_itens || 0,
        };
    } catch (err) {
        // Tratamento de erro centralizado
        throw createError({ statusCode: 500, message: err.message });
    }
});
```

## 2. Consumindo no Frontend (SSR Friendly)

Use `useFetch` para garantir que a dados sejam carregados no servidor durante a
renderização inicial (SSR), melhorando SEO e performance (LCP).

### Exemplo de Uso (`pages/exemplo.vue`)

```vue
<script setup>
const route = useRoute()
const store = useAppStore()

// Parâmetros reativos
const page = ref(1)
const search = ref('')

// useFetch com Watchers
// A URL '/api/infra/escolas' baterá no nosso endpoint BFF
const { data, pending, error, refresh } = await useFetch('/api/infra/escolas', {
  query: computed(() => ({
    id_empresa: store.company?.empresa_id, // Passa contexto da empresa
    pagina: page.value,
    busca: search.value
  })),
  watch: [page, search], // Refaz a chamada se estes mudarem
  immediate: true // Carrega imediatamente
})

// Dados computados para uso no template
const items = computed(() => data.value?.items || [])
const total = computed(() => data.value?.total || 0)
</script>

<template>
  <div v-if="pending">Carregando...</div>
  <ul v-else>
    <li v-for="item in items" :key="item.id">{{ item.nome }}</li>
  </ul>
</template>
```

## Benefícios Deste Padrão

1. **Segurança**: A lógica de qual RPC chamar e como tratar os parâmetros fica
   no servidor, não exposta no bundle JS do cliente.
2. **Abstração**: O frontend não precisa saber se o dado vem de uma RPC
   `escolas_get` ou `escolas_v2_get`. O endpoint `/api/infra/escolas` mantém o
   contrato.
3. **Performance SSR**: O `useFetch` hidrata o estado inicial vindo do servidor,
   evitando "Loading spinners" desnecessários no primeiro acesso.
4. **Tipagem**: As respostas já vêm limpas e formatadas, reduzindo lógica de
   transformação nos componentes Vue.
