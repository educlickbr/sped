<script setup>
const props = defineProps({
  isOpen: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits(["close"])
const router = useRouter()
const store = useAppStore() // Assuming useAppStore has auth info

// Navigation Helper
const handleNavigation = (path) => {
  if (!path) return
  router.push(path)
  emit("close")
}

// Close Helper
const closeMenu = () => {
  emit("close")
}

// User Info Helpers
const userName = computed(() => {
  if (store.nome) return store.nome
  if (store.user && store.user.email) return store.user.email.split('@')[0]
  return 'Convidado'
})

const userInitial = computed(() => {
  return userName.value ? userName.value.charAt(0).toUpperCase() : 'C'
})
</script>

<template>
  <div
    class="fixed inset-0 z-[100] transform transition-transform duration-500 ease-[cubic-bezier(0.4,0,0.2,1)] bg-background flex flex-col font-sans p-4 gap-4"
    :class="isOpen ? 'translate-x-0' : 'translate-x-[102%]'"
  >
    <!-- 1. Header -->
    <header class="bg-div-15 border border-secondary/20 rounded-xl px-4 py-3 flex items-center justify-between shadow-sm shrink-0">
      <div class="flex items-center gap-3">
        <div class="w-10 h-10 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-lg border border-primary/20">
           {{ userInitial }}
        </div>
        <div>
          <h2 class="text-sm font-black text-text leading-tight">
            Olá, {{ userName.split(' ')[0] }}
          </h2>
          <p class="text-[10px] text-secondary font-bold uppercase tracking-wider">Menu Principal</p>
        </div>
      </div>

      <div class="flex items-center gap-2">
        <!-- Close Button -->
        <button
          @click="closeMenu"
          class="p-2 text-secondary hover:text-danger hover:bg-danger/10 rounded-lg transition-all"
        >
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
        </button>
      </div>
    </header>

    <!-- 2. Scrollable Content Area -->
    <main class="flex-1 overflow-y-auto px-2 space-y-8 max-w-7xl mx-auto w-full custom-scrollbar">
      
      <!-- Menu Grid Structure -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        
        <!-- ISLAND: Processo Seletivo -->
        <div class="space-y-4">
          <div class="flex items-center gap-2 px-1">
             <div class="w-1.5 h-1.5 rounded-full bg-primary/60"></div>
             <h3 class="text-xs font-black text-secondary tracking-[0.2em] uppercase">Processo Seletivo</h3>
          </div>
          
          <div class="bg-div-15 border border-secondary/10 rounded-2xl overflow-hidden shadow-sm">
            <!-- Processos Abertos -->
            <button @click="handleNavigation('/processo_seletivo')" class="menu-item group">
              <div class="menu-icon bg-primary/10 text-primary">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
              </div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold text-text group-hover:text-primary transition-colors">Processos Abertos</span>
                <span class="text-[10px] text-secondary font-medium">Inscreva-se em cursos</span>
              </div>
              <svg class="ml-auto text-secondary/20 group-hover:text-primary/60 transition-colors" xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"></polyline></svg>
            </button>

            <!-- Seleção Candidatos -->
            <button class="menu-item group border-t border-secondary/5 cursor-not-allowed opacity-60">
              <div class="menu-icon bg-secondary/10 text-secondary">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>
              </div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold text-text group-hover:text-primary transition-colors">Seleção de Candidatos</span>
                <span class="text-[10px] text-secondary font-medium">Gerenciamento de inscritos (Em breve)</span>
              </div>
            </button>

             <!-- Meus Processos -->
            <button class="menu-item group border-t border-secondary/5 cursor-not-allowed opacity-60">
              <div class="menu-icon bg-secondary/10 text-secondary">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>
              </div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold text-text group-hover:text-primary transition-colors">Meus Processos</span>
                <span class="text-[10px] text-secondary font-medium">Acompanhe suas inscrições (Em breve)</span>
              </div>
            </button>

             <!-- Adequação Documentos -->
            <button class="menu-item group border-t border-secondary/5 cursor-not-allowed opacity-60">
              <div class="menu-icon bg-secondary/10 text-secondary">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path><line x1="12" y1="11" x2="12" y2="17"></line><line x1="9" y1="14" x2="15" y2="14"></line></svg>
              </div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold text-text group-hover:text-primary transition-colors">Adequação de Documentos</span>
                <span class="text-[10px] text-secondary font-medium">Envio de pendências (Em breve)</span>
              </div>
            </button>

             <!-- Painel Seleção -->
             <button class="menu-item group border-t border-secondary/5 cursor-not-allowed opacity-60">
              <div class="menu-icon bg-secondary/10 text-secondary">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"></rect><line x1="8" y1="21" x2="16" y2="21"></line><line x1="12" y1="17" x2="12" y2="21"></line></svg>
              </div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold text-text group-hover:text-primary transition-colors">Painel de Seleção</span>
                <span class="text-[10px] text-secondary font-medium">Dashboard administrativo (Em breve)</span>
              </div>
            </button>
          </div>
        </div>

        <!-- ISLAND: Educacional -->
        <div class="space-y-4">
          <div class="flex items-center gap-2 px-1">
             <div class="w-1.5 h-1.5 rounded-full bg-orange-500/60"></div>
             <h3 class="text-xs font-black text-secondary tracking-[0.2em] uppercase">Educacional</h3>
          </div>
          
          <div class="bg-div-15 border border-secondary/10 rounded-2xl overflow-hidden shadow-sm">
            <!-- Matrículas -->
            <button class="menu-item group cursor-not-allowed opacity-60">
              <div class="menu-icon bg-orange-500/10 text-orange-500">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path></svg>
              </div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold text-text group-hover:text-primary transition-colors">Matrículas</span>
                <span class="text-[10px] text-secondary font-medium">Gestão de matrículas (Em breve)</span>
              </div>
            </button>

            <!-- Carômetro -->
            <button class="menu-item group border-t border-secondary/5 cursor-not-allowed opacity-60">
              <div class="menu-icon bg-orange-500/10 text-orange-500">
                   <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect><circle cx="8.5" cy="8.5" r="1.5"></circle><polyline points="21 15 16 10 5 21"></polyline></svg>
              </div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold text-text group-hover:text-primary transition-colors">Carômetro</span>
                <span class="text-[10px] text-secondary font-medium">Visualização de turmas (Em breve)</span>
              </div>
            </button>

             <!-- Criar Cursos -->
            <button class="menu-item group border-t border-secondary/5 cursor-not-allowed opacity-60">
              <div class="menu-icon bg-orange-500/10 text-orange-500">
                   <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
              </div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold text-text group-hover:text-primary transition-colors">Criar Cursos/Turmas</span>
                <span class="text-[10px] text-secondary font-medium">Gestão acadêmica (Em breve)</span>
              </div>
            </button>

          </div>
        </div>

      </div>
    </main>

    <!-- 3. Footer -->
    <footer class="p-6 text-center border-t border-secondary/5">
      <p class="text-[10px] text-secondary/30 font-black tracking-[0.3em] uppercase">SPED • MENU GLOBAL</p>
    </footer>
  </div>
</template>

<style scoped>
.menu-item {
  @apply w-full flex items-center gap-3 p-3 transition-all duration-200 hover:bg-div-30 active:scale-[0.99];
}

.menu-icon {
  @apply w-9 h-9 rounded-lg flex items-center justify-center shrink-0 transition-transform duration-300 group-hover:scale-110 group-hover:rotate-3;
}

.custom-scrollbar::-webkit-scrollbar {
  width: 4px;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: rgba(var(--color-secondary-rgb), 0.1);
  border-radius: 10px;
}
</style>
