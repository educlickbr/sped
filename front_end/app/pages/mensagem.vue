<script setup lang="ts">
definePageMeta({
    layout: false,
    pageTransition: {
        name: 'fade',
        mode: 'out-in'
    }
})

const store = useAppStore()
const router = useRouter()

// If no message, redirect to home/login
if (!store.statusMessage.message) {
    router.push('/login')
}

// Icon based on type
const icon = computed(() => {
    switch(store.statusMessage.type) {
        case 'success':
            return `<svg xmlns="http://www.w3.org/2000/svg" class="w-16 h-16 text-primary" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>`
        case 'error':
            return `<svg xmlns="http://www.w3.org/2000/svg" class="w-16 h-16 text-danger" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>`
        default: // info
            return `<svg xmlns="http://www.w3.org/2000/svg" class="w-16 h-16 text-primary" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>`
    }
})

const handleAction = () => {
    if (store.statusMessage.actionPath) {
        router.push(store.statusMessage.actionPath)
    } else {
        router.push('/')
    }
}
</script>

<template>
<div class="min-h-screen flex items-center justify-center bg-[#0a0a0c] p-6 font-sans relative overflow-hidden">
    
    <!-- Background Accents -->
    <div class="absolute inset-0 pointer-events-none">
        <div class="absolute top-[-10%] right-[-5%] w-[600px] h-[600px] bg-primary/10 rounded-full blur-[180px]"></div>
        <div class="absolute bottom-[0%] left-[-10%] w-[500px] h-[500px] bg-secondary/10 rounded-full blur-[150px]"></div>
    </div>

    <div class="w-full max-w-md relative z-10">
        <div class="bg-div-15 backdrop-blur-2xl border border-white/5 rounded-xl p-8 md:p-12 shadow-2xl text-center flex flex-col items-center gap-6">
            
            <div class="w-24 h-24 rounded-full bg-white/5 flex items-center justify-center mb-2 icon-animate" v-html="icon"></div>

            <h1 v-if="store.statusMessage.title" class="text-2xl font-black text-white uppercase tracking-[0.2em]">
                {{ store.statusMessage.title }}
            </h1>

            <p class="text-secondary text-sm font-medium leading-relaxed">
                {{ store.statusMessage.message }}
            </p>

            <button 
                @click="handleAction"
                class="mt-4 w-full bg-primary text-white font-black py-4 rounded-lg text-sm uppercase tracking-widest shadow-lg shadow-primary/20 hover:bg-[#b81151] hover:shadow-primary/40 hover:-translate-y-0.5 transition-all active:scale-[0.98]"
            >
                {{ store.statusMessage.actionLabel || 'Continuar' }}
            </button>

        </div>
    </div>
</div>
</template>

<style>
/* Nome da transição definido no definePageMeta: 'fade' */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.5s ease; /* 1.5s é muito lento, testamos com 0.5s */
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* Garante que o estado final/inicial seja 100% visível */
.fade-enter-to,
.fade-leave-from {
  opacity: 1;
}

/* Icon Animation - Mantive o seu */
.icon-animate svg {
    animation: pop-in 1.8s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards;
}

@keyframes pop-in {
    0% { opacity: 0; transform: scale(0.5); }
    100% { opacity: 1; transform: scale(1); }
}
</style>