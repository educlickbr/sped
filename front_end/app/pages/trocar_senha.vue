<script setup lang="ts">
import { useToast } from '../../composables/useToast'
const supabase = useSupabaseClient()
const router = useRouter()
const store = useAppStore()
const { showToast } = useToast()

const password = ref('')
const confirmPassword = ref('')
const showPassword = ref(false)
const showConfirmPassword = ref(false)
const loading = ref(false)

const handleUpdate = async () => {
    if (!password.value || !confirmPassword.value) {
        showToast('Preencha todos os campos.', { type: 'error' })
        return
    }

    if (password.value !== confirmPassword.value) {
        showToast('As senhas não conferem.', { type: 'error' })
        return
    }

    if (password.value.length < 6) {
        showToast('A senha deve ter pelo menos 6 caracteres.', { type: 'error' })
        return
    }

    loading.value = true
    try {
        const { error } = await supabase.auth.updateUser({
            password: password.value
        })

        if (error) throw error

        store.setStatusMessage({
            title: 'Senha Alterada!',
            message: 'Sua senha foi atualizada com sucesso. Você já pode fazer login com a nova credencial.',
            type: 'success',
            actionLabel: 'Ir para Login',
            actionPath: '/login'
        })
        
        router.push('/mensagem')

    } catch (err: any) {
        console.error('Update password error:', err)
        showToast(err.message || 'Erro ao atualizar senha.', { type: 'error' })
    } finally {
        loading.value = false
    }
}
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-[#0a0a0c] p-6 font-sans relative overflow-hidden">
    
    <!-- Background Accents -->
    <div class="absolute inset-0 pointer-events-none">
        <div class="absolute top-[20%] left-[20%] w-[300px] h-[300px] bg-primary/20 rounded-full blur-[150px]"></div>
    </div>

    <div class="w-full max-w-md relative z-10">
        
        <!-- Card -->
        <div class="bg-div-15 backdrop-blur-2xl border border-white/5 rounded-[2.5rem] p-8 md:p-12 shadow-2xl">
            
            <div class="flex flex-col items-center mb-8">
                <div class="mb-6">
                    <img src="https://spedppull.b-cdn.net/site/logosp.png" alt="Logo SPED" class="h-16 w-auto object-contain" />
                </div>
                <h1 class="text-2xl font-black text-white uppercase tracking-[0.2em] text-center">
                    Nova Senha
                </h1>
                <p class="text-xs font-bold text-secondary/60 uppercase tracking-widest mt-2 text-center">
                    Defina sua nova senha de acesso
                </p>
            </div>

            <form @submit.prevent="handleUpdate" class="space-y-4">
                
                <!-- Password Field -->
                <div class="space-y-2">
                    <label for="password" class="text-[10px] font-black uppercase tracking-widest text-secondary/60 ml-1">Senha</label>
                    <div class="relative group">
                        <input 
                            v-model="password"
                            :type="showPassword ? 'text' : 'password'" 
                            id="password"
                            required
                            placeholder="••••••••"
                            class="w-full bg-white/5 border border-white/10 rounded-2xl px-5 py-4 text-sm font-bold text-white focus:outline-none focus:ring-2 focus:ring-primary/40 focus:border-primary/40 transition-all placeholder:text-white/10 group-hover:border-white/20"
                        />
                        <button 
                            type="button"
                            @click="showPassword = !showPassword"
                            class="absolute right-5 top-1/2 -translate-y-1/2 text-white/10 hover:text-primary transition-colors focus:outline-none"
                        >
                            <svg v-if="!showPassword" class="w-5 h-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg>
                            <svg v-else class="w-5 h-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path><line x1="1" y1="1" x2="23" y2="23"></line></svg>
                        </button>
                    </div>
                </div>

                <!-- Confirm Password Field -->
                <div class="space-y-2">
                    <label for="confirmPassword" class="text-[10px] font-black uppercase tracking-widest text-secondary/60 ml-1">Confirmar Senha</label>
                    <div class="relative group">
                        <input 
                            v-model="confirmPassword"
                            :type="showConfirmPassword ? 'text' : 'password'" 
                            id="confirmPassword"
                            required
                            placeholder="••••••••"
                            class="w-full bg-white/5 border border-white/10 rounded-2xl px-5 py-4 text-sm font-bold text-white focus:outline-none focus:ring-2 focus:ring-primary/40 focus:border-primary/40 transition-all placeholder:text-white/10 group-hover:border-white/20"
                        />
                        <button 
                            type="button"
                            @click="showConfirmPassword = !showConfirmPassword"
                            class="absolute right-5 top-1/2 -translate-y-1/2 text-white/10 hover:text-primary transition-colors focus:outline-none"
                        >
                            <svg v-if="!showConfirmPassword" class="w-5 h-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg>
                            <svg v-else class="w-5 h-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path><line x1="1" y1="1" x2="23" y2="23"></line></svg>
                        </button>
                    </div>
                </div>

                <div class="pt-4">
                     <button 
                        type="submit" 
                        :disabled="loading"
                        class="w-full bg-primary text-white font-black py-5 rounded-2xl text-sm uppercase tracking-[0.2em] shadow-lg shadow-primary/20 hover:bg-[#b81151] hover:shadow-primary/40 hover:-translate-y-0.5 transition-all active:scale-[0.98] flex items-center justify-center gap-3 disabled:opacity-50 disabled:pointer-events-none"
                    >
                        <span v-if="loading" class="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
                        {{ loading ? 'Atualizando...' : 'Atualizar Senha' }}
                    </button>
                </div>

            </form>

        </div>

    </div>
  </div>
</template>
