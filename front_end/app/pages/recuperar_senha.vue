<script setup lang="ts">
import { useToast } from '../../composables/useToast'
const supabase = useSupabaseClient()
const router = useRouter()
const store = useAppStore()
const { showToast } = useToast()

const email = ref('')
const loading = ref(false)

const handleRecover = async () => {
    if (!email.value) {
        showToast('Por favor, informe seu e-mail.', { type: 'error' })
        return
    }

    loading.value = true
    try {
        // Assume URL base is configured correctly in Supabase or using window.location.origin
        const redirectTo = `${window.location.origin}/trocar_senha`
        
        const { error } = await supabase.auth.resetPasswordForEmail(email.value, {
            redirectTo: redirectTo
        })

        if (error) throw error

        store.setStatusMessage({
            title: 'Verifique seu E-mail',
            message: `Enviamos um link de recuperação para ${email.value}. Clique no link para criar uma nova senha.`,
            type: 'success',
            actionLabel: 'Voltar ao Login',
            actionPath: '/login'
        })

        router.push('/mensagem')

    } catch (err: any) {
        console.error('Recover error:', err)
        showToast(err.message || 'Erro ao enviar e-mail de recuperação.', { type: 'error' })
    } finally {
        loading.value = false
    }
}
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-[#0a0a0c] p-6 font-sans relative overflow-hidden">
    
    <!-- Background Accents -->
    <div class="absolute inset-0 pointer-events-none">
        <div class="absolute top-[-10%] left-[-5%] w-[600px] h-[600px] bg-primary/20 rounded-full blur-[180px]"></div>
        <div class="absolute bottom-[0%] right-[-10%] w-[500px] h-[500px] bg-primary/15 rounded-full blur-[150px]"></div>
    </div>

    <div class="w-full max-w-md relative z-10">
        
        <!-- Card -->
        <div class="bg-div-15 backdrop-blur-2xl border border-white/5 rounded-[2.5rem] p-8 md:p-12 shadow-2xl">
            
            <div class="flex flex-col items-center mb-8">
                <div class="mb-6">
                    <img src="https://spedppull.b-cdn.net/site/logosp.png" alt="Logo SPED" class="h-16 w-auto object-contain" />
                </div>
                <h1 class="text-2xl font-black text-white uppercase tracking-[0.2em] text-center">
                    Recuperar Senha
                </h1>
                <p class="text-xs font-bold text-secondary/60 uppercase tracking-widest mt-2 text-center">
                    Informe seu e-mail para receber o link
                </p>
            </div>

            <form @submit.prevent="handleRecover" class="space-y-6">
                
                <div class="space-y-2">
                    <label for="email" class="text-[10px] font-black uppercase tracking-widest text-secondary/60 ml-1">E-mail</label>
                    <div class="relative group">
                        <input 
                            v-model="email"
                            type="email" 
                            id="email"
                            required
                            placeholder="seu@email.com"
                            class="w-full bg-white/5 border border-white/10 rounded-2xl px-5 py-4 text-sm font-bold text-white focus:outline-none focus:ring-2 focus:ring-primary/40 focus:border-primary/40 transition-all placeholder:text-white/10 group-hover:border-white/20"
                        />
                         <div class="absolute right-5 top-1/2 -translate-y-1/2 text-white/10 group-focus-within:text-primary transition-colors">
                            <svg class="w-5 h-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"></path><polyline points="22,6 12,13 2,6"></polyline></svg>
                        </div>
                    </div>
                </div>

                <button 
                    type="submit" 
                    :disabled="loading"
                    class="w-full bg-primary text-white font-black py-5 rounded-2xl text-sm uppercase tracking-[0.2em] shadow-lg shadow-primary/20 hover:bg-[#b81151] hover:shadow-primary/40 hover:-translate-y-0.5 transition-all active:scale-[0.98] flex items-center justify-center gap-3 disabled:opacity-50 disabled:pointer-events-none"
                >
                    <span v-if="loading" class="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
                    {{ loading ? 'Enviando...' : 'Enviar Link' }}
                </button>

            </form>

            <div class="mt-8 text-center space-y-4">
                <NuxtLink to="/login" class="inline-block text-[10px] font-black uppercase tracking-widest text-secondary/60 hover:text-white transition-colors">
                    ← Voltar para Login
                </NuxtLink>
            </div>

        </div>

    </div>
  </div>
</template>
