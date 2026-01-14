<script setup>
const store = useAppStore()
const isMenuOpen = useState('menu-open', () => false)

onMounted(() => {
   store.initTheme()
   store.initSession() // Single BFF call for everything
})
</script>

<template>
  <div class="h-screen bg-background flex flex-col md:flex-row gap-4 p-2 md:p-5 overflow-hidden font-sans text-text transition-colors duration-300">
    
    <!-- Full Page Menu Overlay -->
    <FullPageMenu :isOpen="isMenuOpen" @close="isMenuOpen = false" />

    <!-- Main Content Panel (Contains Header + Content) -->
    <main class="flex-1 flex flex-col gap-4 h-full overflow-hidden relative">
      
         <!-- Detached Header (Inside Main) -->
         <!-- 
            LAYOUT HEADER (MOBILE VS DESKTOP):
            - Padding Vertical (Top/Bottom): py-2 (Mobile) | md:py-3 (Desktop)
            - Padding Horizontal (Left/Right): px-2 (Mobile) | md:px-4 (Desktop)
            - Background: bg-transparent (Mobile) | md:bg-div-15 (Desktop)
            - Border: border-0 (Mobile) | md:border (Desktop)
         -->
         <header class="bg-transparent md:bg-div-15 px-2 py-1 md:px-4 md:py-3 rounded-lg shrink-0 flex items-center justify-between shadow-none md:shadow-sm border-0 md:border border-secondary/5 transition-all">
         
         <!-- Brand / User Avatar -->
         <div class="flex items-center gap-3">
               <div class="hidden md:flex w-8 h-8 rounded bg-primary/10 text-primary items-center justify-center font-bold text-sm shadow-sm border border-primary/10 overflow-hidden relative">
                  <img 
                     v-if="store.user && store.imagem_user && store.hash_base" 
                     :src="store.hash_base + store.imagem_user" 
                     class="w-full h-full object-cover absolute inset-0"
                     alt="Foto"
                  />
                  <span v-else>S</span>
               </div>
               <div class="flex flex-col leading-none gap-0.5">
                  <!-- 
                     FONTS & TEXT (MOBILE VS DESKTOP):
                     - Título Tamanho: text-[10px] (Mobile) | md:text-xs (Desktop)
                     - Subtítulo Tamanho: text-[9px] (Mobile) | md:text-[10px] (Desktop)
                  -->
                  <h1 class="text-[12px] md:text-xs font-black text-primary uppercase tracking-[0.2em]">Processo Seletivo</h1>
                  <p class="text-[10px] md:text-[10px] text-secondary font-bold opacity-80">São Paulo Escola de Dança</p>
               </div>
         </div>

        <!-- Right Controls: Only Menu Button -->
        <div class="flex items-center">

           <!-- Auth State Buttons -->
           <div v-if="store.user" class="flex items-center gap-4">
               
               <!-- Menu Trigger (Far Right) -->
               <button 
                  @click="isMenuOpen = true"
                  class="w-10 h-10 flex flex-col items-center justify-center gap-1.5 rounded-lg text-secondary hover:text-primary hover:bg-div-30 transition-all group"
                  title="Menu"
               >
                  <span class="w-5 h-0.5 bg-current rounded-full transition-all group-hover:w-6"></span>
                  <span class="w-5 h-0.5 bg-current rounded-full transition-all group-hover:w-4"></span>
                  <span class="w-5 h-0.5 bg-current rounded-full transition-all group-hover:w-6"></span>
               </button>
           </div>

           <NuxtLink v-else to="/login" class="flex items-center gap-2 text-[10px] font-black uppercase tracking-wider text-text hover:text-primary bg-div-30 px-3 py-1.5 rounded transition-all hover:bg-div-30/80 border border-transparent hover:border-secondary/5">
              <span>Entrar</span>
           </NuxtLink>
        </div>
      </header>

      <!-- Main Scrollable Content -->
      <div class="flex-1 overflow-y-auto rounded-lg custom-scrollbar flex flex-col gap-4 px-1">
         <slot />
         
         <footer class="py-6 text-center text-[9px] uppercase tracking-widest text-secondary/30 font-bold border-t border-secondary/5 mt-auto">
            © {{ new Date().getFullYear() }} São Paulo Escola de Dança
         </footer>
      </div>

    </main>

    <!-- Sidebar (Right Side) -->
    <aside class="w-full md:w-[320px] lg:w-[380px] shrink-0 hidden lg:flex flex-col gap-4 h-full">
       <div class="bg-div-15 h-full rounded-lg border border-secondary/5 p-5 shadow-sm overflow-y-auto flex flex-col gap-6">
          <slot name="sidebar">
              <!-- Default Content / Skeleton can go here if needed -->
          </slot>
       </div>
    </aside>

  </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 4px;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: rgba(var(--color-secondary-rgb), 0.1);
  border-radius: 10px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
</style>
