<script setup lang="ts">
import './assets/css/style.css'
const isLoading = ref(true)

const nuxtApp = useNuxtApp()
const router = useRouter()

// Min wait time for smooth UX (as requested "um pouco de aguarde")
const MIN_LOADING_TIME = 500

let loadStartTime = Date.now()
let safetyTimeout: any

// START: Show immediately (fixes FOUC)
nuxtApp.hook('page:start', () => {
    clearTimeout(safetyTimeout)
    isLoading.value = true
    loadStartTime = Date.now()
    
    // Safety: 8s max
    safetyTimeout = setTimeout(() => {
        isLoading.value = false
    }, 8000)
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
    // Remove inline loader
    const inlineLoader = document.getElementById('initial-loader')
    if (inlineLoader) {
        inlineLoader.style.opacity = '0'
        setTimeout(() => inlineLoader.remove(), 400)
    }

    // Force finish Vue loader
    setTimeout(finishLoading, 200)
    document.body.classList.add('hydrated')
})
</script>

<template>
  <div>
    <!-- INLINE LOADER: Rendered immediately by browser (Critical CSS) -->
    <!-- Content styles are inline to guarantee immediate paint before external CSS loads -->
    <div id="initial-loader" style="position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; background-color: #0c0c0c; z-index: 99999; display: flex; align-items: center; justify-content: center; transition: opacity 0.4s ease;">
        <div class="loader-content">
            <div class="spinner-outer"></div>
            <div class="spinner-inner"></div>
            <h2 class="loader-text">AGUARDE</h2>
        </div>
    </div>

    <!-- MAIN APP: Hidden via CSS until hydration complete + Hidden via Vue while loading -->
    <div class="bypass-fouc" v-show="!isLoading">
        <NuxtLayout>
            <NuxtPage />
        </NuxtLayout>
    </div>

    <!-- VUE LOADER: Takes over for internal navigation -->
    <LoadingOverlay :show="isLoading" />
  </div>
</template>

<style>
/* STRICT FOUC PROTECTION */
/* Default: Hidden immediately by CSS parser */
.bypass-fouc {
    opacity: 0;
    visibility: hidden; 
    transition: opacity 0.5s ease;
}

/* Only visible when JS says we are ready */
body.hydrated .bypass-fouc {
    opacity: 1;
    visibility: visible;
}

/* CRITICAL CSS FOR INLINE LOADER */
/* This ensures it displays instantly even before Vue/JS loads */
#initial-loader {
    position: fixed;
    inset: 0;
    z-index: 99999; /* Higher than everything */
    background-color: #0c0c0c;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: opacity 0.4s ease;
}

#initial-loader .loader-content {
    position: relative;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
}

#initial-loader .spinner-outer {
    width: 80px;
    height: 80px;
    border: 2px solid rgba(221, 17, 104, 0.2);
    border-top-color: #dd1168;
    border-radius: 50%;
    animation: spin 1s linear infinite;
}

#initial-loader .spinner-inner {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 60px;
    height: 60px;
    border: 2px solid rgba(221, 17, 104, 0.1);
    border-bottom-color: rgba(221, 17, 104, 0.6);
    border-radius: 50%;
    animation: spin-reverse 1.5s linear infinite;
}

#initial-loader .loader-text {
    margin-top: 20px;
    color: white;
    font-family: sans-serif;
    font-weight: 900;
    letter-spacing: 0.2em;
    font-size: 1.2rem;
    text-transform: uppercase;
    position: absolute;
    top: 90px;
}

@keyframes spin {
    to { transform: rotate(360deg); }
}

@keyframes spin-reverse {
    to { transform: rotate(-360deg) translate(-50%, -50%); /* Fix transform conflict if needed, but better use separate element */ }
}

/* Hide body content until hydrated if desired, preventing flash */

</style>
