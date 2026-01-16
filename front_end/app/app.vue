<script setup lang="ts">
import './assets/css/style.css'
const isLoading = ref(true)

const nuxtApp = useNuxtApp()
const router = useRouter()

// Min wait time for smooth UX (reduced for performance feel)
const MIN_LOADING_TIME = 50

let loadStartTime = Date.now()
let safetyTimeout: any

// START: Show immediately (fixes FOUC)
nuxtApp.hook('page:start', () => {
    clearTimeout(safetyTimeout)
    isLoading.value = true
    loadStartTime = Date.now()
    
    // Safety: 2s max (reduced from 8s)
    safetyTimeout = setTimeout(() => {
        isLoading.value = false
    }, 2000)
})

// FUNCTION: Smooth finish
const finishLoading = () => {
    clearTimeout(safetyTimeout)
    const elapsed = Date.now() - loadStartTime
    const remaining = Math.max(0, MIN_LOADING_TIME - elapsed)
    
    setTimeout(() => {
        isLoading.value = false
    }, remaining)
}

// FINISH: Standard hook
nuxtApp.hook('page:finish', finishLoading)
nuxtApp.hook('app:error', () => {
    isLoading.value = false
})

// WATCHER: Backup safety net. If route changes, we ARE done.
// This fixes the "8s stuck" issue if hooks misfire.
watch(() => router.currentRoute.value.path, () => {
    // Give Vue a moment to mount/render, then force finish
    setTimeout(finishLoading, 100)
})

// LIFECYCLE: Ensure loader clears on initial load (hydration)
// This is critical because page:start/finish might not fire on F5 refresh depending on Nuxt version/SSR
onMounted(() => {
    // 1. Revelar o container principal que foi escondido via nuxt.config.ts
    const nuxtContainer = document.getElementById('__nuxt')
    if (nuxtContainer) {
        nuxtContainer.style.display = 'block'
    }

    // 2. Remover o loader injetado pelo Nitro (Server Side)
    const nitroLoader = document.getElementById('nitro-initial-loader')
    if (nitroLoader) {
        nitroLoader.style.opacity = '0'
        setTimeout(() => nitroLoader.remove(), 200)
    }

    // Force finish Vue loader
    setTimeout(finishLoading, 50)
    document.body.classList.add('hydrated')
})
</script>

<template>
  <div>
    <!-- MAIN APP: O container #__nuxt é escondido via CSS no nuxt.config.ts por padrão -->
    <div v-show="!isLoading">
        <NuxtLayout>
            <NuxtPage />
        </NuxtLayout>
    </div>

    <!-- VUE LOADER: Gerencia o feedback em navegações internas via router watcher -->
    <LoadingOverlay :show="isLoading" />
  </div>
</template>

<style>
/* Estilos globais se necessários */
</style>
