<template>
  <div class="min-h-screen flex flex-col items-center justify-center bg-background text-text">
    <h1 class="text-4xl font-bold text-primary mb-4">Bem-vindo ao Sped Nuxt</h1>
    <p class="text-lg mb-8">Página inicial temporária.</p>
    <div class="flex gap-4">
      <NuxtLink to="/teste-tailwind" class="px-4 py-2 bg-secondary text-white rounded hover:bg-secondary-hover transition">
        Ver Teste de Cores (Tailwind)
      </NuxtLink>
      <NuxtLink to="/login" class="px-4 py-2 border border-primary text-primary rounded hover:bg-primary hover:text-white transition">
        Ir para Login
      </NuxtLink>
    </div>
  </div>
</template>
