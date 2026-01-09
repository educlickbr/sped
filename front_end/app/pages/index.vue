<script setup lang="ts">
const user = useSupabaseUser()
const redirectCookie = useCookie<any>('redirect_after_login')

// Always show loading
const isLoading = ref(true)

onMounted(async () => {
  // Add a small delay for better UX (optional, but helps avoid layout shift flickering)
  await new Promise(resolve => setTimeout(resolve, 500))

  if (user.value) {
    // Logged In Logic
    if (redirectCookie.value && redirectCookie.value.procedencia_form) {
      // User came from "Inscrever-se" flow
      console.log('User logged in with pending form. Redirecting...')
      const target = redirectCookie.value
      
      // Clear flag/cookie to avoid loop (or just clear procedencia_form)
      redirectCookie.value = null 

      navigateTo({
        path: target.path,
        query: target.query
      })
    } else {
      // Standard logged in user -> Processo Seletivo (for now)
      navigateTo('/processo_seletivo')
    }
  } else {
    // Not Logged In -> Processo Seletivo
    navigateTo('/processo_seletivo')
  }
})
</script>

<template>
  <div class="min-h-screen flex flex-col items-center justify-center bg-background text-text">
     <!-- While deciding, we show nothing or just the overlay which is global -->
     <LoadingOverlay :show="true" />
  </div>
</template>
