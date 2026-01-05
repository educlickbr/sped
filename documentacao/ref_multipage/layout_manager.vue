<script setup>
const store = useAppStore()
</script>

<template>
  <div class="h-screen bg-background flex flex-col md:flex-row gap-4 p-5 overflow-hidden font-sans">
    <!-- Main Content Panel -->
    <main class="flex-1 flex flex-col gap-3 h-full overflow-hidden">
      <!-- Fixed Header Area (Unified with background) -->
      <header class="bg-div-15 px-4 py-3 rounded shrink-0 flex flex-col md:flex-row md:items-center justify-between gap-6 transition-all border border-secondary/5">
        <!-- Left Section: Title & Icon Context -->
        <div class="flex items-center gap-4">
          <slot name="header-icon" />
          
          <div class="min-w-0">
            <h1 class="text-xl font-bold text-text leading-tight tracking-tight flex items-center gap-3">
              <slot name="header-title" />
            </h1>
            <p class="text-xs text-secondary font-medium mt-0.5 opacity-60">
              <slot name="header-subtitle" />
            </p>
          </div>
        </div>

        <!-- Right Section: Actions + Controls -->
        <div class="flex items-center gap-4 w-full md:w-auto flex-1 justify-end">
          <slot name="header-actions" />
          
          <!-- Sleek Global Controls (No frames, more spacing) -->
          <div class="flex items-center gap-2 ml-2">
            <!-- Theme Toggle -->
            <button @click="store.toggleTheme()" class="w-9 h-9 flex items-center justify-center rounded text-secondary hover:text-primary hover:bg-div-15 transition-all" title="Alternar Tema">
              <svg v-if="!store.isDark" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path></svg>
              <svg v-else xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5"></circle><line x1="12" y1="1" x2="12" y2="3"></line><line x1="12" y1="21" x2="12" y2="23"></line><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line><line x1="1" y1="12" x2="3" y2="12"></line><line x1="21" y1="12" x2="23" y2="12"></line><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line></svg>
            </button>

            <!-- Menu Button -->
            <button @click="store.toggleMenu()" class="w-9 h-9 flex items-center justify-center rounded text-secondary hover:text-primary hover:bg-div-15 transition-all" title="Menu Principal">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="12" x2="21" y2="12"></line><line x1="3" y1="6" x2="21" y2="6"></line><line x1="3" y1="18" x2="21" y2="18"></line></svg>
            </button>
          </div>
        </div>
      </header>

      <!-- Navigation Tabs (Sleek Border) -->
      <nav class="flex items-center gap-1 border-b border-primary px-2 overflow-x-auto no-scrollbar shrink-0 min-h-[40px]">
        <slot name="tabs" />
      </nav>

      <!-- Main Scrollable Content -->
      <div class="flex-1 overflow-y-auto pr-1 flex flex-col gap-2 custom-scrollbar">
        <slot /> <!-- Nuxt Layout Default Slot -->
      </div>
    </main>

    <!-- Sidebar Dashboard Panel -->
    <aside v-if="$slots.sidebar" class="w-full md:w-[320px] lg:w-[380px] shrink-0 h-full overflow-hidden hidden md:block">
      <div class="bg-div-15 h-full rounded border border-secondary/5 p-5 shadow-sm overflow-y-auto custom-scrollbar">
        <slot name="sidebar" />
      </div>
    </aside>
    
    <!-- Render modais within the layout so they can be teleported -->
    <slot name="modals" />
  </div>
</template>

<style scoped>
.no-scrollbar::-webkit-scrollbar { display: none; }
.no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
.custom-scrollbar::-webkit-scrollbar { width: 4px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(var(--color-secondary-rgb), 0.1); border-radius: 10px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
</style>
