<script setup>
const props = defineProps({
  isOpen: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits(["close"])
const route = useRoute()
const router = useRouter()
const appStore = useAppStore()
const toast = useToastStore()
const supabase = useSupabaseClient()

const isInicio = computed(() => route.path === '/inicio')

const handleNavigation = (path) => {
  router.push(path)
  emit("close")
}

const isDark = ref(false)

onMounted(() => {
  const savedTheme = localStorage.getItem("theme")
  if (savedTheme) {
    isDark.value = savedTheme === "dark"
  } else {
    isDark.value = window.matchMedia("(prefers-color-scheme: dark)").matches
  }
  applyTheme()
})

const applyTheme = () => {
  if (isDark.value) {
    document.documentElement.setAttribute("data-theme", "dark")
  } else {
    document.documentElement.removeAttribute("data-theme")
  }
}

const toggleTheme = () => {
  isDark.value = !isDark.value
  localStorage.setItem("theme", isDark.value ? "dark" : "light")
  applyTheme()
}

const closeMenu = () => {
  emit("close")
}

const openExternalLink = (url) => {
  window.open(url, "_blank")
}

const handleLogout = async () => {
  try {
    // Show loading immediately to mask the menu closing and redirection
    appStore.setLoading(true)
    
    await appStore.logout()
    emit("close")
    router.push('/')
    toast.showToast('Logout realizado com sucesso.', 'success')
  } catch (error) {
    if (!error.message?.includes('session_not_found')) {
      toast.showToast(error.message || 'Erro ao sair.', 'error')
    }
    // Still try to redirect to / to re-orchestrate
    router.push('/')
  }
}

// Derived user name
const userName = computed(() => {
  const user = appStore.user
  if (user && user.user_metadata && user.user_metadata.full_name) {
    return user.user_metadata.full_name
  }
  if (user && user.email) {
    return user.email.split("@")[0]
  }
  return "Usuário"
})

// Permissions using the new store helper
const hasAccess = (allowedRoles) => {
  return appStore.hasRole(allowedRoles)
}
</script>

<template>
  <div
    class="fixed inset-0 z-[100] transform transition-transform duration-500 ease-[cubic-bezier(0.4,0,0.2,1)] bg-background flex flex-col font-sans p-4 gap-4"
    :class="isOpen ? 'translate-x-0' : 'translate-x-[102%]'"
  >
    <!-- 1. Sleek Header -->
    <header class="bg-div-15 border border-secondary/20 rounded px-4 py-3 flex items-center justify-between shadow-sm shrink-0">
      <div class="flex items-center gap-3">
        <div class="w-9 h-9 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-lg">
           {{ userName.charAt(0).toUpperCase() }}
        </div>
        <div>
          <h2 class="text-sm font-bold text-text leading-tight">
            Olá, {{ userName.split(' ')[0] }}
          </h2>
          <p class="text-[10px] text-secondary font-medium">Acesso rápido ao sistema</p>
        </div>
      </div>

      <div class="flex items-center gap-2">
        <!-- Theme Toggle -->
        <button
          @click="toggleTheme"
          class="p-2 text-secondary hover:text-primary hover:bg-div-30 rounded transition-all"
          title="Alterar Tema"
        >
          <svg v-if="isDark" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path></svg>
          <svg v-else xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5"></circle><line x1="12" y1="1" x2="12" y2="3"></line><line x1="12" y1="21" x2="12" y2="23"></line><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line><line x1="1" y1="12" x2="3" y2="12"></line><line x1="21" y1="12" x2="23" y2="12"></line><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line></svg>
        </button>

        <!-- Home/Close -->
        <button
          v-if="!isInicio"
          @click="closeMenu"
          class="p-2 text-secondary hover:text-danger hover:bg-danger/5 rounded transition-all"
        >
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
        </button>
      </div>
    </header>

    <!-- 2. Scrollable Content Area -->
    <main class="flex-1 overflow-y-auto px-2 space-y-8 max-w-6xl mx-auto w-full">
      
      <!-- Utility Actions (Logout) -->
      <section class="flex justify-end pt-2">
         <button
          @click="handleLogout"
          class="flex items-center gap-2 px-4 py-2 bg-danger/10 text-danger rounded hover:bg-danger/20 transition-all font-bold text-xs"
        >
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
          Sair da Conta
        </button>
      </section>

      <!-- Menu Grid Structure -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        
        <!-- Section: Administrativo -->
        <div v-if="hasAccess([ROLES.ADMIN])" class="space-y-4">
          <h3 class="text-xs font-black text-secondary tracking-[0.2em] uppercase px-1">Administrativo</h3>
          <div class="bg-div-15 border border-secondary/10 rounded overflow-hidden shadow-sm">
            <button @click="handleNavigation('/infraestrutura')" class="menu-item group">
              <div class="menu-icon bg-blue-500/10 text-blue-500"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path><polyline points="9 22 9 12 15 12 15 22"></polyline></svg></div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold text-text group-hover:text-primary transition-colors">Infraestrutura</span>
                <span class="text-[10px] text-secondary">Escolas e Prédios</span>
              </div>
            </button>
            <button @click="handleNavigation('/educacional')" class="menu-item group border-t border-secondary/5">
              <div class="menu-icon bg-orange-500/10 text-orange-500"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 10v6M2 10l10-5 10 5-10 5z"></path><path d="M6 12v5c3 3 9 3 12 0v-5"></path></svg></div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold text-text group-hover:text-primary transition-colors">Educacional</span>
                <span class="text-[10px] text-secondary">Matrículas e Turmas</span>
              </div>
            </button>
            <button @click="handleNavigation('/usuarios')" class="menu-item group border-t border-secondary/5">
              <div class="menu-icon bg-purple-500/10 text-purple-500"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg></div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold text-text group-hover:text-primary transition-colors">Usuários</span>
                <span class="text-[10px] text-secondary">Gestão de Equipe</span>
              </div>
            </button>
          </div>
        </div>

        <!-- Section: Biblioteca -->
        <div v-if="hasAccess([ROLES.ADMIN])" class="space-y-4">
          <h3 class="text-xs font-black text-secondary tracking-[0.2em] uppercase px-1">Biblioteca</h3>
          <div class="bg-div-15 border border-secondary/10 rounded overflow-hidden shadow-sm">
            <button @click="handleNavigation('/biblioteca/catalogo')" class="menu-item group">
              <div class="menu-icon bg-emerald-500/10 text-emerald-500"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="7" width="20" height="14" rx="2" ry="2"></rect><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"></path></svg></div>
              <span class="text-sm font-bold text-text group-hover:text-primary">Catálogo</span>
            </button>
            <button @click="handleNavigation('/biblioteca/obras')" class="menu-item group border-t border-secondary/5">
              <div class="menu-icon bg-emerald-500/10 text-emerald-500"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path></svg></div>
              <span class="text-sm font-bold text-text group-hover:text-primary">Gestão de Livros</span>
            </button>
            <button @click="handleNavigation('/biblioteca/inventario')" class="menu-item group border-t border-secondary/5">
              <div class="menu-icon bg-emerald-500/10 text-emerald-500"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="8" y1="6" x2="21" y2="6"></line><line x1="8" y1="12" x2="21" y2="12"></line><line x1="8" y1="18" x2="21" y2="18"></line><line x1="3" y1="6" x2="3.01" y2="6"></line><line x1="3" y1="12" x2="3.01" y2="12"></line><line x1="3" y1="18" x2="3.01" y2="18"></line></svg></div>
              <span class="text-sm font-bold text-text group-hover:text-primary">Inventário</span>
            </button>
            <button @click="handleNavigation('/biblioteca/reservas')" class="menu-item group border-t border-secondary/5">
              <div class="menu-icon bg-emerald-500/10 text-emerald-500"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg></div>
              <span class="text-sm font-bold text-text group-hover:text-primary">Reservas</span>
            </button>
          </div>
        </div>

        <!-- Section: Aprendizado -->
        <div class="space-y-4">
          <h3 class="text-xs font-black text-secondary tracking-[0.2em] uppercase px-1">Aprendizado</h3>
          <div class="bg-div-15 border border-secondary/10 rounded overflow-hidden shadow-sm">
             <button @click="handleNavigation('/lms')" v-if="hasAccess([ROLES.ADMIN, ROLES.PROFESSOR])" class="menu-item group">
              <div class="menu-icon bg-sky-500/10 text-sky-500"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"></path><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"></path></svg></div>
              <span class="text-sm font-bold text-text group-hover:text-primary">LMS Acadêmico</span>
            </button>
            <button @click="handleNavigation('/lms-consumo')" class="menu-item group border-t border-secondary/5">
              <div class="menu-icon bg-sky-500/10 text-sky-500"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="5 3 19 12 5 21 5 3"></polygon></svg></div>
              <span class="text-sm font-bold text-text group-hover:text-primary">Conteúdo Digital</span>
            </button>
            <button @click="handleNavigation('/biblioteca')" class="menu-item group border-t border-secondary/5">
              <div class="menu-icon bg-sky-500/10 text-sky-500"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path></svg></div>
              <span class="text-sm font-bold text-text group-hover:text-primary">Biblioteca Digital</span>
            </button>
            <button @click="handleNavigation('/lms-avaliacao')" v-if="hasAccess([ROLES.ADMIN, ROLES.PROFESSOR])" class="menu-item group border-t border-secondary/5">
              <div class="menu-icon bg-sky-500/10 text-sky-500"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg></div>
              <span class="text-sm font-bold text-text group-hover:text-primary">Avaliações</span>
            </button>
          </div>
        </div>

        <!-- Section: Interação -->
        <div class="space-y-4">
          <h3 class="text-xs font-black text-secondary tracking-[0.2em] uppercase px-1">Interação</h3>
          <div class="bg-div-15 border border-secondary/10 rounded overflow-hidden shadow-sm">
            <button @click="openExternalLink('https://salas.conecte-rv.app/27jVggY/biblioteca-caruaru')" class="menu-item group">
              <div class="menu-icon bg-pink-500/10 text-pink-500"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"></rect><line x1="8" y1="21" x2="16" y2="21"></line><line x1="12" y1="17" x2="12" y2="21"></line></svg></div>
              <span class="text-sm font-bold text-text group-hover:text-primary">Ambiente 3D</span>
            </button>
            <button @click="openExternalLink('https://meet-caruaru.conectetecnologia.com/')" class="menu-item group border-t border-secondary/5">
              <div class="menu-icon bg-pink-500/10 text-pink-500"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M23 7l-7 5 7 5V7z"></path><rect x="1" y="5" width="15" height="14" rx="2" ry="2"></rect></svg></div>
              <span class="text-sm font-bold text-text group-hover:text-primary">Meeting</span>
            </button>
             <button @click="openExternalLink('http://caruaru-1.conectetecnologia.com/site/home/home.htm')" v-if="hasAccess([ROLES.ADMIN, ROLES.PROFESSOR])" class="menu-item group border-t border-secondary/5">
              <div class="menu-icon bg-pink-500/10 text-pink-500"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="2" y1="12" x2="22" y2="12"></line><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"></path></svg></div>
              <span class="text-sm font-bold text-text group-hover:text-primary">Portal Pedagógico</span>
            </button>
          </div>
        </div>

      </div>
    </main>

    <!-- 3. Footer -->
    <footer class="p-6 text-center">
      <p class="text-[10px] text-secondary/50 font-bold tracking-widest uppercase">CONECTE EDUCATION &copy; 2025</p>
    </footer>
  </div>
</template>

<style scoped>
.menu-item {
  @apply w-full flex items-center gap-4 p-4 transition-all duration-200 hover:bg-div-30 active:scale-[0.98];
}

.menu-icon {
  @apply w-10 h-10 rounded flex items-center justify-center shrink-0 transition-transform group-hover:scale-110;
}

main::-webkit-scrollbar {
  width: 4px;
}
main::-webkit-scrollbar-thumb {
  background: rgba(var(--color-secondary), 0.1);
  border-radius: 10px;
}
</style>
