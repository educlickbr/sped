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
const route = useRoute()

// Active Route Helper
const isActive = (path) => {
    return route.path === path || route.path.startsWith(path + '/')
}

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
    <!-- 
       LAYOUT HEADER (MOBILE VS DESKTOP):
       - Padding Vertical (Top/Bottom): py-2 (Mobile) | md:py-3 (Desktop)
       - Padding Horizontal (Left/Right): px-2 (Mobile) | md:px-4 (Desktop)
       - Background: bg-transparent (Mobile) | md:bg-div-15 (Desktop)
    -->
    <header class="bg-transparent md:bg-div-15 px-1 py-2 md:px-4 md:py-3 rounded-lg flex items-center justify-between shadow-none md:shadow-sm border-0 md:border border-secondary/5 shrink-0">
      <div class="flex items-center gap-3">
        <div class="hidden md:flex w-8 h-8 rounded bg-primary/10 text-primary items-center justify-center font-bold text-sm border border-primary/10 shadow-sm overflow-hidden relative">
           <img 
              v-if="store.imagem_user && store.hash_base" 
              :src="store.hash_base + store.imagem_user" 
              class="w-full h-full object-cover absolute inset-0"
              alt="Foto"
           />
           <span v-else>{{ userInitial }}</span>
        </div>
        <div class="flex flex-col leading-none gap-0.5">
          <!-- 
             FONTS & TEXT (MOBILE VS DESKTOP):
             - Título Tamanho: text-[10px] (Mobile) | md:text-xs (Desktop)
             - Subtítulo Tamanho: text-[9px] (Mobile) | md:text-[10px] (Desktop)
          -->
          <h2 class="text-[12px] md:text-xs font-black text-text uppercase tracking-[0.2em] leading-none">
            Olá, {{ userName.split(' ')[0] }}
          </h2>
          <p class="text-[10px] md:text-[10px] text-secondary font-bold opacity-80 leading-none">Menu Principal</p>
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
          
          <div class="bg-div-15 border border-secondary/10 rounded-xl overflow-hidden shadow-sm">
            <!-- Processos Abertos -->
            <button @click="handleNavigation('/processo_seletivo')" class="menu-item group">
              <div class="menu-icon" :class="isActive('/processo_seletivo') ? 'bg-primary/10 text-primary' : 'bg-secondary/10 text-secondary'">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
              </div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold transition-colors" :class="isActive('/processo_seletivo') ? 'text-primary' : 'text-text group-hover:text-primary'">Processos Abertos</span>
                <span class="text-[10px] text-secondary font-medium">Inscreva-se em cursos</span>
              </div>
            </button>

            <!-- Seleção Estudantes -->
            <button @click="handleNavigation('/selecao/estudante')" class="menu-item group border-t border-secondary/5">
              <div class="menu-icon" :class="isActive('/selecao/estudante') ? 'bg-primary/10 text-primary' : 'bg-secondary/10 text-secondary'">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>
              </div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold transition-colors" :class="isActive('/selecao/estudante') ? 'text-primary' : 'text-text group-hover:text-primary'">Seleção Estudantes</span>
                <span class="text-[10px] text-secondary font-medium">Candidatos a cursos</span>
              </div>
            </button>

            <!-- Seleção Docentes -->
            <button @click="handleNavigation('/selecao/docente')" class="menu-item group border-t border-secondary/5">
              <div class="menu-icon" :class="isActive('/selecao/docente') ? 'bg-primary/10 text-primary' : 'bg-secondary/10 text-secondary'">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 14l9-5-9-5-9 5 9 5z"></path><path d="M12 14l6.16-3.422a12.083 12.083 0 0 1 .665 6.479A11.952 11.952 0 0 0 12 20.055a11.952 11.952 0 0 0-6.824-2.998 12.078 12.078 0 0 1 .665-6.479L12 14z"></path><path d="M12 14v7"></path><path d="M12 14v7"></path></svg>
              </div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold transition-colors" :class="isActive('/selecao/docente') ? 'text-primary' : 'text-text group-hover:text-primary'">Seleção Docentes</span>
                <span class="text-[10px] text-secondary font-medium">Candidatos a vagas docentes</span>
              </div>
            </button>

             <!-- Meus Processos -->
            <button @click="handleNavigation('/meus-processos')" class="menu-item group border-t border-secondary/5">
              <div class="menu-icon" :class="isActive('/meus-processos') ? 'bg-primary/10 text-primary' : 'bg-secondary/10 text-secondary'">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>
              </div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold transition-colors" :class="isActive('/meus-processos') ? 'text-primary' : 'text-text group-hover:text-primary'">Meus Processos</span>
                <span class="text-[10px] text-secondary font-medium">Acompanhe suas inscrições</span>
              </div>
            </button>



             <!-- Painel Seleção -->
             <button @click="handleNavigation('/selecao/painel')" class="menu-item group border-t border-secondary/5">
              <div class="menu-icon" :class="isActive('/selecao/painel') ? 'bg-primary/10 text-primary' : 'bg-secondary/10 text-secondary'">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"></rect><line x1="8" y1="21" x2="16" y2="21"></line><line x1="12" y1="17" x2="12" y2="21"></line></svg>
              </div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold transition-colors" :class="isActive('/selecao/painel') ? 'text-primary' : 'text-text group-hover:text-primary'">Painel de Seleção</span>
                <span class="text-[10px] text-secondary font-medium">Dashboard administrativo</span>
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
          
          <div class="bg-div-15 border border-secondary/10 rounded-xl overflow-hidden shadow-sm">
            <!-- Matrículas -->
            <button @click="handleNavigation('/matriculas')" class="menu-item group">
              <div class="menu-icon bg-orange-500/10 text-orange-500">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path></svg>
              </div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold text-text group-hover:text-primary transition-colors">Matrículas</span>
                <span class="text-[10px] text-secondary font-medium">Gestão de matrículas</span>
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
      <p class="text-[10px] text-secondary/30 font-black tracking-[0.3em] uppercase">SPEDIGITAL :: NAV</p>
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
