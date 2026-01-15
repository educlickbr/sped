<template>
  <div class="min-h-screen bg-background text-text p-10 font-sans transition-colors duration-300">
    <h1 class="text-4xl font-bold mb-8">Teste de Design System & Tailwind</h1>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
      <!-- Seção de Cores Principais -->
      <div class="bg-div-15 p-6 rounded-lg shadow-lg border border-div-30">
        <h2 class="text-2xl font-semibold mb-4">Botões & Ações</h2>
        <div class="flex flex-wrap gap-4">
          <button class="px-4 py-2 rounded bg-primary text-white hover:bg-primary-dark transition">
            Primary
          </button>
          <button class="px-4 py-2 rounded bg-secondary text-white hover:bg-secondary-hover transition">
            Secondary
          </button>
          <button class="px-4 py-2 rounded border border-primary text-primary hover:bg-primary hover:text-white transition">
            Outline
          </button>
        </div>
      </div>

      <!-- Seção de Feedback -->
      <div class="bg-div-15 p-6 rounded-lg shadow-lg border border-div-30">
        <h2 class="text-2xl font-semibold mb-4">Cores de Estado</h2>
        <div class="space-y-3">
          <div class="flex items-center gap-4">
            <div class="w-12 h-12 rounded bg-success flex items-center justify-center text-white font-bold">OK</div>
            <span>Success (var(--color-success))</span>
          </div>
          <div class="flex items-center gap-4">
            <div class="w-12 h-12 rounded bg-warning flex items-center justify-center text-white font-bold">!</div>
            <span>Warning (var(--color-warning))</span>
          </div>
          <div class="flex items-center gap-4">
            <div class="w-12 h-12 rounded bg-danger flex items-center justify-center text-white font-bold">X</div>
            <span>Danger (var(--color-danger))</span>
          </div>
        </div>
      </div>

      <!-- Seção de Superfícies -->
      <div class="col-span-1 md:col-span-2">
        <h2 class="text-2xl font-semibold mb-4">Superfícies (Divs)</h2>
        <div class="grid grid-cols-3 gap-4 text-center">
          <div class="p-4 rounded bg-background border border-div-30">
            Background
          </div>
          <div class="p-4 rounded bg-div-15 text-text">
            Div-15
          </div>
          <div class="p-4 rounded bg-div-30 text-text">
            Div-30
          </div>
        </div>
      </div>
      <!-- Seção de Navegação -->
       <div class="col-span-1 md:col-span-2 bg-div-15 p-6 rounded-lg shadow-lg border border-div-30">
        <h2 class="text-2xl font-semibold mb-4">Navegação & Testes</h2>
        <button 
            @click="testMessage"
            class="px-6 py-3 rounded-lg bg-indigo-600 text-white font-bold hover:bg-indigo-700 transition"
        >
            Testar Página de Mensagem
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
const store = useAppStore()
const router = useRouter()

const testMessage = () => {
    store.statusMessage = {
        title: 'Inscrição enviada com sucesso!',
        message: 'Inscrição enviada com sucesso! Confira suas inscrições e os documentos enviados em Meus Processos, basta clicar no botão abaixo.',
        type: 'success',
        actionLabel: 'Meus Processos',
        actionPath: '/meus-processos'
    }
    router.push('/mensagem')
}
</script>
