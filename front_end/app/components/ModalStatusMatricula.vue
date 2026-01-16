<script setup lang="ts">
import { ref, watch } from 'vue';
import { useToast } from '../../composables/useToast';

const props = defineProps<{
    isOpen: boolean;
    aluno: any; // Expected to have id (matricula id), nome, sobrenome, status
}>();

const emit = defineEmits(['close', 'update-status']);
const { showToast } = useToast();

const isLoading = ref(false);
const newStatus = ref('');
const statusOptions = ['Ativa', 'Cancelada', 'Trancamento', 'Anulada'];

const initStatus = () => {
    if (props.aluno && props.aluno.status) {
        const current = props.aluno.status;
        const found = statusOptions.find(s => s.toLowerCase() === current.toLowerCase());
        newStatus.value = found || current;
    } else {
        newStatus.value = 'Ativa';
    }
};

watch(() => props.isOpen, (newVal) => {
    if (newVal) {
        initStatus();
    }
});

watch(() => props.aluno, () => {
    if (props.isOpen) {
        initStatus();
    }
});

const saveStatus = async () => {
    if (!props.aluno || !props.aluno.id) return;
    
    isLoading.value = true;
    try {
        await $fetch('/api/matriculas/status', {
            method: 'POST',
            body: {
                id_matricula: props.aluno.id, // This is matricula ID from the list
                status: newStatus.value
            }
        });
        
        showToast(`Status alterado para ${newStatus.value}`, {
             type: 'info'
        });

        emit('update-status');
        emit('close');
        
    } catch (e: any) {
        console.error('Erro ao atualizar status:', e);
        showToast(e.statusMessage || 'Erro ao atualizar status', {
             type: 'error'
        });
    } finally {
        isLoading.value = false;
    }
};

</script>

<template>
    <div v-if="isOpen" class="fixed inset-0 z-[9999] flex items-center justify-center bg-black/80 backdrop-blur-sm p-4">
        <div class="bg-[#16161E] border border-white/10 rounded-xl w-full max-w-md shadow-2xl relative overflow-hidden">
            
            <div class="p-6 border-b border-white/5">
                <h3 class="text-lg font-bold text-white mb-1">Alterar Status da Matrícula</h3>
                <p class="text-sm text-secondary">
                    {{ aluno?.nome }} {{ aluno?.sobrenome }}
                </p>
                <p class="text-xs text-secondary/50 mt-1 font-mono">
                    ID: {{ aluno?.id }}
                </p>
            </div>

            <div class="p-6 space-y-4">
                <div class="space-y-2">
                    <label class="text-sm font-medium text-secondary">Novo Status</label>
                    <div class="relative">
                        <select v-model="newStatus" class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:border-primary focus:outline-none appearance-none h-10">
                            <option v-for="opt in statusOptions" :key="opt" :value="opt">{{ opt }}</option>
                        </select>
                         <div class="absolute right-3 top-2.5 pointer-events-none text-secondary">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
                        </div>
                    </div>
                </div>

                <div v-if="newStatus === 'Cancelado'" class="p-3 bg-red-500/10 border border-red-500/20 rounded-lg text-xs text-red-400">
                    <span class="font-bold block mb-1">Atenção:</span>
                    O cancelamento da matrícula pode implicar na perda da vaga e do histórico escolar do período atual.
                </div>
            </div>

            <div class="p-4 border-t border-white/5 flex justify-end gap-2 bg-black/20">
                <button 
                    @click="emit('close')" 
                    class="px-4 py-2 text-sm font-medium text-secondary hover:text-white transition-colors"
                >
                    Cancelar
                </button>
                <button 
                    @click="saveStatus" 
                    :disabled="isLoading || !newStatus"
                    class="px-4 py-2 bg-primary text-white text-sm font-bold rounded-lg hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center gap-2"
                >
                    <svg v-if="isLoading" class="animate-spin h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                    Salvar Alterações
                </button>
            </div>

        </div>
    </div>
</template>
