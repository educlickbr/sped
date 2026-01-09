<script setup>
const props = defineProps({
  show: {
    type: Boolean,
    default: true
  }
})
</script>

<template>
  <Transition name="fade">
    <div
      v-if="show"
      class="fixed inset-0 flex items-center justify-center overflow-hidden transition-colors duration-500"
      style="z-index: 9999; position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;"
      :style="{ 
        backgroundColor: 'var(--color-background, #0c0c0c)',
        pointerEvents: show ? 'auto' : 'none' 
      }"
    >
      <!-- Premium Background: Animated Gradients + Blur -->
      <div class="absolute inset-0 opacity-40">
        <div class="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-primary/40 rounded-full blur-[120px] animate-pulse"></div>
        <div class="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] bg-blue-500/20 rounded-full blur-[120px] animate-pulse" style="animation-delay: 1s"></div>
        <div class="absolute top-[20%] right-[-5%] w-[30%] h-[30%] bg-primary/20 rounded-full blur-[100px] animate-pulse" style="animation-delay: 2s"></div>
      </div>

      <!-- Content -->
      <div class="relative flex flex-col items-center gap-8 px-4 text-center">
        <!-- Logo/Spinner Container -->
        <div class="relative scale-125">
          <!-- Outer Pulsing Ring -->
          <div class="absolute inset-[-12px] rounded-full border border-primary/20 animate-ping"></div>
          
          <!-- Outer Ring -->
          <div class="w-20 h-20 rounded-full border-2 border-primary/20 border-t-primary animate-spin"></div>
          
          <!-- Inner Rotating Ring -->
          <div class="absolute inset-1 rounded-full border-2 border-primary/10 border-b-primary/60 animate-spin-reverse" style="animation-duration: 1.5s"></div>
          
          <!-- Pulsing Core -->
          <div class="absolute inset-6 bg-primary/20 rounded-full flex items-center justify-center animate-pulse">
            <div class="w-2 h-2 bg-primary rounded-full shadow-[0_0_12px_var(--color-primary)]"></div>
          </div>
        </div>

        <!-- Brand Text -->
        <div class="flex flex-col gap-1">
          <h2 
            class="text-2xl font-black tracking-[0.2em] uppercase transition-colors duration-300"
            style="color: var(--color-text, #ffffff); font-family: 'Outfit', sans-serif;"
          >
            Aguarde
          </h2>
          <!-- Subtext/Loading Bits -->
          <div class="flex gap-1.5 justify-center opacity-60">
            <div class="w-1.5 h-1.5 bg-primary rounded-full animate-bounce [animation-delay:-0.3s]"></div>
            <div class="w-1.5 h-1.5 bg-primary rounded-full animate-bounce [animation-delay:-0.15s]"></div>
            <div class="w-1.5 h-1.5 bg-primary rounded-full animate-bounce"></div>
          </div>
        </div>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.fade-enter-active {
  transition: opacity 0.15s ease-out;
}
.fade-leave-active {
  transition: opacity 0.4s ease-in;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

@keyframes spin-reverse {
  from { transform: rotate(0deg); }
  to { transform: rotate(-360deg); }
}

.animate-spin {
  animation: spin 1s linear infinite;
}

.animate-spin-reverse {
  animation: spin-reverse 1.5s linear infinite;
}
</style>
