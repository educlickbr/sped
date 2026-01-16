<script setup lang="ts">
import { ref, watch, computed } from 'vue';

const props = defineProps<{
    isOpen: boolean;
    aluno: any; // Expected to have aluno_id, id_turma, nome, sobrenome
}>();

const emit = defineEmits(['close']);

const isLoading = ref(false);
const diarioData = ref<any>(null);
const error = ref<string | null>(null);

const fetchDiario = async () => {
    if (!props.aluno || !props.aluno.aluno_id || !props.aluno.id_turma) return;

    isLoading.value = true;
    error.value = null;
    diarioData.value = null;

    try {
        const data = await $fetch('/api/matriculas/faltas', {
            params: {
                id_aluno: props.aluno.aluno_id,
                id_turma: props.aluno.id_turma
            }
        });
        diarioData.value = data;
    } catch (e: any) {
        console.error('Erro ao buscar diário:', e);
        error.value = e.message || 'Erro ao carregar dados do diário.';
    } finally {
        isLoading.value = false;
    }
};

watch(() => props.isOpen, (newVal) => {
    if (newVal && props.aluno) {
        fetchDiario();
    }
});

const formatDate = (dateString: string) => {
    if (!dateString) return '--';
    const date = new Date(dateString);
    // Adjust for timezone if needed, but assuming simple date string yyyy-mm-dd
    return date.toLocaleDateString('pt-BR');
};

const getStatusColor = (status: string) => {
    if (!status) return 'bg-gray-500/10 text-gray-500';
    const s = status.toLowerCase();
    if (s === 'presente' || s === 'p') return 'bg-green-500/10 text-green-500 border-green-500/20';
    if (s === 'falta' || s === 'f') return 'bg-red-500/10 text-red-500 border-red-500/20';
    if (s === 'abono' || s === 'a') return 'bg-blue-500/10 text-blue-500 border-blue-500/20';
    return 'bg-gray-500/10 text-gray-500 border-gray-500/20';
}

const getStatusLabel = (status: string) => {
    if (!status) return '-';
    // Return first letter capitalized
    if (status.length <= 1) return status.toUpperCase();
    return status.charAt(0).toUpperCase();
}

</script>

<template>
    <div v-if="isOpen" class="fixed inset-0 z-[9999] flex items-center justify-center bg-black/80 backdrop-blur-sm p-4">
        <!-- Modal Container -->
        <div class="bg-[#16161E] border border-white/10 rounded-xl w-full max-w-2xl max-h-[90vh] flex flex-col shadow-2xl relative">
            
            <!-- Header -->
            <div class="flex items-start justify-between p-6 border-b border-white/5">
                <div>
                    <h3 class="text-lg font-bold text-white flex items-center gap-2">
                        <svg class="w-5 h-5 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"></path></svg>
                        Diário de Classe
                    </h3>
                    <p class="text-sm text-secondary mt-1">
                        {{ aluno?.nome }} {{ aluno?.sobrenome }}
                        <span class="text-xs opacity-50 ml-2" v-if="aluno?.nome_curso">{{ aluno.nome_curso }}</span>
                    </p>
                </div>
                <button @click="emit('close')" class="text-secondary hover:text-white transition-colors">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                </button>
            </div>

            <!-- Content -->
            <div class="flex-1 overflow-y-auto p-6 scrollbar-thin scrollbar-thumb-white/10 scrollbar-track-transparent">
                
                <!-- Loading -->
                <div v-if="isLoading" class="flex flex-col items-center justify-center py-12">
                     <svg class="animate-spin h-8 w-8 text-primary mb-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                     <p class="text-sm text-secondary">Carregando dados de frequência...</p>
                </div>

                <!-- Error -->
                <div v-else-if="error" class="flex flex-col items-center justify-center py-12 text-center text-red-400">
                    <svg class="w-12 h-12 mb-2 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path></svg>
                    <p>{{ error }}</p>
                </div>

                <!-- Data Display -->
                <div v-if="!isLoading && !error && diarioData" class="space-y-6">
                    
                    <!-- Stats Cards -->
                    <div class="grid grid-cols-2 gap-4">
                        <div class="bg-black/20 rounded-lg p-4 border border-white/5 flex flex-col items-center text-center">
                            <span class="text-xs text-secondary font-bold uppercase tracking-wider mb-1">Presença</span>
                            <div class="text-3xl font-bold" :class="Number(diarioData.percentual_presenca) >= 75 ? 'text-green-500' : 'text-red-500'">
                                {{ diarioData.percentual_presenca }}%
                            </div>
                            <span class="text-[10px] text-white/50 mt-1">Mínimo exigido: 75%</span>
                        </div>
                        <div class="bg-black/20 rounded-lg p-4 border border-white/5 flex flex-col items-center text-center">
                            <span class="text-xs text-secondary font-bold uppercase tracking-wider mb-1">Faltas Computadas</span>
                            <div class="text-3xl font-bold text-white">
                                {{ diarioData.horas_faltadas }}h
                            </div>
                            <span class="text-[10px] text-white/50 mt-1">de {{ diarioData.horas_totais_modulo }}h totais</span>
                        </div>
                    </div>

                    <!-- Records List -->
                    <div>
                        <h4 class="text-sm font-bold text-white mb-3 flex items-center gap-2">
                             <svg class="w-4 h-4 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
                            Histórico de Aulas
                        </h4>
                        
                        <div v-if="diarioData.registros && diarioData.registros.length > 0" class="bg-black/20 rounded-lg border border-white/5 overflow-hidden">
                            <div class="grid grid-cols-5 text-[10px] font-bold text-secondary uppercase bg-white/5 p-2 text-center">
                                <div class="text-left pl-2">Data</div>
                                <div v-if="diarioData.qtd_periodos >= 1">P1</div>
                                <div v-if="diarioData.qtd_periodos >= 2">P2</div>
                                <div v-if="diarioData.qtd_periodos >= 3">P3</div>
                                <div v-if="diarioData.qtd_periodos >= 4">P4</div>
                            </div>
                            
                            <div class="divide-y divide-white/5">
                                <div v-for="(log, idx) in diarioData.registros" :key="idx" class="grid grid-cols-5 text-sm p-3 items-center text-center hover:bg-white/5 transition-colors">
                                    <div class="text-left font-mono text-white/80 pl-2">{{ formatDate(log.data) }}</div>
                                    
                                    <div v-if="diarioData.qtd_periodos >= 1" class="flex justify-center">
                                        <span class="w-6 h-6 flex items-center justify-center rounded border text-xs font-bold" :class="getStatusColor(log.p1)">
                                            {{ getStatusLabel(log.p1) }}
                                        </span>
                                    </div>
                                    <div v-if="diarioData.qtd_periodos >= 2" class="flex justify-center">
                                        <span class="w-6 h-6 flex items-center justify-center rounded border text-xs font-bold" :class="getStatusColor(log.p2)">
                                            {{ getStatusLabel(log.p2) }}
                                        </span>
                                    </div>
                                    <div v-if="diarioData.qtd_periodos >= 3" class="flex justify-center">
                                        <span class="w-6 h-6 flex items-center justify-center rounded border text-xs font-bold" :class="getStatusColor(log.p3)">
                                            {{ getStatusLabel(log.p3) }}
                                        </span>
                                    </div>
                                    <div v-if="diarioData.qtd_periodos >= 4" class="flex justify-center">
                                        <span class="w-6 h-6 flex items-center justify-center rounded border text-xs font-bold" :class="getStatusColor(log.p4)">
                                            {{ getStatusLabel(log.p4) }}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div v-else class="text-center py-8 text-secondary text-sm">
                            Nenhum registro de aula encontrado.
                        </div>

                    </div>

                </div>

            </div>

             <!-- Footer -->
             <div class="p-4 border-t border-white/5 flex justify-end">
                <button @click="emit('close')" class="px-4 py-2 bg-white/5 hover:bg-white/10 text-white text-sm font-medium rounded-lg transition-colors">
                    Fechar
                </button>
            </div>

        </div>
    </div>
</template>
