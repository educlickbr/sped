<script setup>
const store = useAppStore()
const menuAberto = ref(true)

const toggleMenu = () => {
  menuAberto.value = !menuAberto.value
}

// Session is initialized globally in app.vue
</script>

<template>
  <div class="min-h-screen bg-background text-text font-sans">
    
    <!-- Main Content Area -->
    <main class="p-8 max-w-4xl mx-auto flex flex-col items-center justify-center min-h-screen text-center space-y-6">
        <h1 class="text-4xl font-black text-primary tracking-tight">Bem-vindo ao Conecte</h1>
        <p class="text-secondary max-w-md">Utilize o menu lateral para navegar entre os módulos do sistema.</p>
        
        <button 
          @click="toggleMenu" 
          class="mt-4 px-8 py-3 bg-primary text-white font-bold rounded shadow-lg hover:shadow-primary/20 transition-all hover:-translate-y-1 active:scale-95 uppercase tracking-wide"
        >
          Abrir Menu de Módulos
        </button>
    </main>

    <!-- Full Page Menu -->
    <FullPageMenu 
      :is-open="menuAberto" 
      @close="toggleMenu"
    />
  </div>
</template>
