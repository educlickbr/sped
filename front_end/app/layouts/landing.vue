<script setup>
const store = useAppStore()

onMounted(() => {
   store.initTheme()
})
</script>

<template>
  <div class="h-screen bg-background flex flex-col md:flex-row gap-4 p-5 overflow-hidden font-sans text-text transition-colors duration-300">
    
    <!-- Main Content Panel (Contains Header + Content) -->
    <main class="flex-1 flex flex-col gap-4 h-full overflow-hidden relative">
      
      <!-- Detached Header (Inside Main) -->
      <header class="bg-div-15 px-4 py-3 rounded-lg shrink-0 flex items-center justify-between shadow-sm border border-secondary/5 transition-all">
        
        <!-- Brand -->
        <div class="flex items-center gap-3">
          <div class="w-8 h-8 rounded bg-primary/10 text-primary flex items-center justify-center font-bold text-sm shadow-sm border border-primary/10">
            S
          </div>
          <div class="flex flex-col leading-none">
             <h1 class="text-xs font-black text-primary uppercase tracking-[0.2em]">Processo Seletivo</h1>
             <p class="text-[10px] text-secondary font-bold opacity-80">Instituto Federal</p>
          </div>
        </div>

        <!-- Right Controls -->
        <div class="flex items-center gap-3">
           <button @click="store.toggleTheme()" class="w-8 h-8 flex items-center justify-center rounded text-secondary hover:text-primary hover:bg-div-30 transition-all font-bold">
              <svg v-if="store.isDark" xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path></svg>
              <svg v-else xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5"></circle><line x1="12" y1="1" x2="12" y2="3"></line><line x1="12" y1="21" x2="12" y2="23"></line><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line><line x1="1" y1="12" x2="3" y2="12"></line><line x1="21" y1="12" x2="23" y2="12"></line><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line></svg>
           </button>

           <div class="w-[1px] h-4 bg-secondary/10"></div>

           <NuxtLink to="/login" class="flex items-center gap-2 text-[10px] font-black uppercase tracking-wider text-text hover:text-primary bg-div-30 px-3 py-1.5 rounded transition-all hover:bg-div-30/80 border border-transparent hover:border-secondary/5">
              <span>Entrar</span>
           </NuxtLink>
        </div>
      </header>

      <!-- Main Scrollable Content -->
      <div class="flex-1 overflow-y-auto rounded-lg custom-scrollbar flex flex-col gap-4 pr-1">
         <slot />
         
         <footer class="py-6 text-center text-[9px] uppercase tracking-widest text-secondary/30 font-bold border-t border-secondary/5 mt-auto">
            © {{ new Date().getFullYear() }} Conecte Education
         </footer>
      </div>

    </main>

    <!-- Sidebar (Right Side) -->
    <aside class="w-full md:w-[320px] lg:w-[380px] shrink-0 hidden lg:flex flex-col gap-4 h-full">
       <div class="bg-div-15 h-full rounded-lg border border-secondary/5 p-5 shadow-sm overflow-y-auto flex flex-col gap-6">
          
           <!-- Widget: Instructions -->
           <div>
              <h4 class="text-[9px] font-black text-primary uppercase tracking-[0.2em] mb-4 flex items-center gap-2">
                 <span class="w-1.5 h-1.5 rounded-full bg-primary"></span>
                 Instruções
              </h4>
              <p class="text-[11px] text-secondary font-medium leading-relaxed mb-4">
                 Para se inscrever, selecione o tipo de candidatura e filtre pela área de interesse.
              </p>
              <div class="space-y-2">
                 <div class="flex items-center gap-3 text-[10px] font-bold text-text/80 bg-background px-3 py-2 rounded-md border border-secondary/5">
                    <span class="text-primary font-black">1.</span> Escolha o curso
                 </div>
                 <div class="flex items-center gap-3 text-[10px] font-bold text-text/80 bg-background px-3 py-2 rounded-md border border-secondary/5">
                    <span class="text-primary font-black">2.</span> Inscreva-se
                 </div>
                 <div class="flex items-center gap-3 text-[10px] font-bold text-text/80 bg-background px-3 py-2 rounded-md border border-secondary/5">
                    <span class="text-primary font-black">3.</span> Acompanhe
                 </div>
              </div>
           </div>
           
           <div class="w-full h-[1px] bg-secondary/10"></div>

           <!-- Widget: Links -->
           <div>
              <h4 class="text-[9px] font-black text-secondary uppercase tracking-[0.2em] mb-3">Links Úteis</h4>
              <nav class="flex flex-col gap-1.5">
                 <a href="#" class="text-[11px] font-bold text-secondary hover:text-primary transition-colors flex items-center gap-1 group">
                    <span class="group-hover:translate-x-1 transition-transform duration-200">→</span> Editais
                 </a>
                 <a href="#" class="text-[11px] font-bold text-secondary hover:text-primary transition-colors flex items-center gap-1 group">
                    <span class="group-hover:translate-x-1 transition-transform duration-200">→</span> Ajuda
                 </a>
              </nav>
           </div>
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
