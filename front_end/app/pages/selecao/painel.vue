<script setup lang="ts">
import { getAnoSemestre } from '../../../utils/seletivo';

const client = useSupabaseClient();
const isLoading = ref(false);

const currentArea = ref('Extensão'); // Default Tab Label
const areaMap: Record<string, string> = {
    'Extensão': 'extensao',
    'Regulares': 'regulares',
    'Cursos Livres': 'cursos_livres'
};
const currentAreaValue = computed(() => areaMap[currentArea.value] || 'extensao');

const anoSemestre = ref(getAnoSemestre());
const dashboardData = ref<any>(null);

const fetchDashboard = async () => {
    isLoading.value = true;
    try {
        const { data, error } = await (client.rpc as any)('nxt_get_dashboard_demographics', {
            p_ano_semestre: anoSemestre.value,
            p_tipo_processo: 'seletivo',
            p_tipo_candidatura: 'estudante',
            p_area: currentAreaValue.value
        });

        if (error) throw error;
        dashboardData.value = data;
    } catch (e) {
        console.error('Error fetching dashboard:', e);
    } finally {
        isLoading.value = false;
    }
};

watch([currentArea, anoSemestre], () => {
    fetchDashboard();
});

onMounted(() => {
    fetchDashboard();
});

const getStatusColor = (status: string) => {
    const map: Record<string, string> = {
        'Aguardando': 'text-yellow-400',
        'Matriculado': 'text-green-400',
        'Aprovado': 'text-blue-400',
        'Recusado': 'text-red-400',
        'Suplente': 'text-orange-400'
    };
    return map[status] || 'text-white';
};

const getStatusLabel = (status: string) => {
     return status || 'Aguardando';
};

const getTotal = (arr: any[]) => {
    if (!arr) return 0;
    return arr.reduce((acc, curr) => acc + (Number(curr.qtd) || 0), 0) || 1; 
};

const getRealTotal = (arr: any[]) => {
     if (!arr) return 0;
    return arr.reduce((acc, curr) => acc + (Number(curr.qtd) || 0), 0);
};

// --- Sorting & Display Logic ---

// Income Order Mapping (Value -> Priority)
const incomeOrder = [
    'ate_meio', 'Até meio salário-mínimo',
    'ate_um', 'Até 1 salário-mínimo',
    'um_dois', 'De 1 a 2 salários-mínimos',
    'dois_cinco', 'De 2 a 5 salários-mínimos',
    'cinco_dez', 'De 5 a 10 salários-mínimos',
    'acima_dez', 'Acima de 10 salários-mínimos'
];

const sortedIncome = computed(() => {
    if (!dashboardData.value?.demographics?.renda) return [];
    return [...dashboardData.value.demographics.renda].sort((a, b) => {
        const idxA = incomeOrder.indexOf(a.label);
        const idxB = incomeOrder.indexOf(b.label);
        // If not found, put at end
        return (idxA === -1 ? 999 : idxA) - (idxB === -1 ? 999 : idxB);
    });
});

const sortedGender = computed(() => {
    if (!dashboardData.value?.demographics?.genero) return [];
    // Sort by Quantity Descending
    return [...dashboardData.value.demographics.genero].sort((a, b) => b.qtd - a.qtd);
});

const sortedRace = computed(() => {
    if (!dashboardData.value?.demographics?.raca) return [];
    // Sort by Quantity Descending
    return [...dashboardData.value.demographics.raca].sort((a, b) => b.qtd - a.qtd);
});

// Helper to format label (remove underscores, capitalize)
const formatLabel = (txt: string) => {
    if (!txt) return 'Não Informado';
    // If it's one of our known values, map to nice text? 
    // For now, simple replace/capitalize is requested/implied.
    return txt.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
};

</script>

<template>
    <NuxtLayout name="base">
        <!-- Main Container -->
        <div class="bg-div-15 rounded-xl p-6 md:p-8">
            <!-- TABS -->
            <div class="border-b border-secondary/10 mb-6">
                <div class="flex items-center gap-8">
                    <button 
                        v-for="(val, label) in areaMap" 
                        :key="val"
                        @click="currentArea = label as string"
                        class="text-sm font-bold pb-4 relative transition-colors whitespace-nowrap"
                        :class="currentArea === label ? 'text-primary' : 'text-secondary hover:text-white'"
                    >
                        {{ label }}
                        <span v-if="currentArea === label" class="absolute bottom-0 left-0 w-full h-0.5 bg-primary rounded-full"></span>
                    </button>
                </div>
            </div>

            <!-- CONTROLS -->
            <div class="flex justify-end mb-8">
                <select v-model="anoSemestre" class="bg-[#16161E] border border-white/5 text-white text-xs rounded-lg focus:ring-1 focus:ring-primary focus:border-primary p-2.5 pr-8 outline-none cursor-pointer w-40 appearance-none bg-[url('data:image/svg+xml;charset=utf-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20fill%3D%22none%22%20viewBox%3D%220%200%2020%2020%22%3E%3Cpath%20stroke%3D%22%236B7280%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22round%22%20stroke-width%3D%221.5%22%20d%3D%22M6%208l4%204%204-4%22%2F%3E%3C%2Fsvg%3E')] bg-[length:1.25rem_1.25rem] bg-no-repeat bg-[right_0.5rem_center]">
                    <option :value="getAnoSemestre(undefined, -1)">{{ getAnoSemestre(undefined, -1) }}</option>
                    <option :value="getAnoSemestre()">{{ getAnoSemestre() }} (Atual)</option>
                    <option :value="getAnoSemestre(undefined, 1)">{{ getAnoSemestre(undefined, 1) }}</option>
                </select>
            </div>

            <!-- LOADING -->
            <div v-if="isLoading && !dashboardData" class="flex justify-center py-20">
                <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-primary"></div>
            </div>

            <!-- DASHBOARD CONTENT -->
            <div v-else-if="dashboardData" class="space-y-8">
                
                <!-- 1. STATUS CARDS -->
                 <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4">
                    <div v-for="(count, status) in dashboardData.status_counts" :key="status" class="bg-[#16161E] border border-white/5 rounded-xl p-4 flex flex-col items-center justify-center min-h-[100px]">
                        <span class="text-3xl font-black mb-1" :class="getStatusColor(String(status))">{{ count }}</span>
                        <span class="text-[10px] uppercase font-bold text-secondary tracking-wider">{{ getStatusLabel(String(status)) }}</span>
                    </div>
                 </div>

                <!-- 2. DEMOGRAPHICS -->
                <div>
                    <h3 class="text-xs font-bold text-secondary uppercase tracking-wider mb-4">Demografia e Perfil</h3>
                    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                        
                        <!-- GÊNERO -->
                        <div class="bg-[#16161E] border border-white/5 rounded-xl p-5 flex flex-col h-full">
                            <h4 class="text-sm font-bold text-white mb-4">Identidade de Gênero</h4>
                            <div class="space-y-4 flex-1">
                                <div v-for="(item, idx) in sortedGender" :key="idx">
                                    <div class="flex justify-between text-xs mb-1">
                                        <span class="text-secondary-300 capitalize">{{ formatLabel(item.label) }}</span>
                                        <span class="text-white font-bold">{{ item.qtd }}</span>
                                    </div>
                                    <div class="w-full h-2 bg-white/5 rounded-full overflow-hidden">
                                        <!-- Using a specific distinct color -->
                                        <div class="h-full bg-pink-500 rounded-full" 
                                             :style="{ width: `${(item.qtd / getTotal(dashboardData.demographics.genero)) * 100}%` }">
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                         <!-- RAÇA -->
                        <div class="bg-[#16161E] border border-white/5 rounded-xl p-5 flex flex-col h-full">
                            <h4 class="text-sm font-bold text-white mb-4">Cor / Raça</h4>
                            <div class="space-y-4 flex-1">
                                <div v-for="(item, idx) in sortedRace" :key="idx">
                                    <div class="flex justify-between text-xs mb-1">
                                        <span class="text-secondary-300 capitalize">{{ formatLabel(item.label) }}</span>
                                        <span class="text-white font-bold">{{ item.qtd }}</span>
                                    </div>
                                    <div class="w-full h-2 bg-white/5 rounded-full overflow-hidden">
                                        <div class="h-full bg-blue-500 rounded-full" 
                                             :style="{ width: `${(item.qtd / getTotal(dashboardData.demographics.raca)) * 100}%` }">
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- RENDA -->
                        <div class="bg-[#16161E] border border-white/5 rounded-xl p-5 flex flex-col h-full">
                            <h4 class="text-sm font-bold text-white mb-4">Renda Familiar</h4>
                            <div class="space-y-4 flex-1">
                                <div v-for="(item, idx) in sortedIncome" :key="idx">
                                    <div class="flex justify-between text-xs mb-1">
                                        <span class="text-secondary-300 capitalize">{{ formatLabel(item.label) }}</span>
                                        <span class="text-white font-bold">{{ item.qtd }}</span>
                                    </div>
                                    <div class="w-full h-2 bg-white/5 rounded-full overflow-hidden">
                                        <div class="h-full bg-emerald-500 rounded-full" 
                                             :style="{ width: `${(item.qtd / getTotal(dashboardData.demographics.renda)) * 100}%` }">
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- FAIXA ETÁRIA -->
                        <div class="bg-[#16161E] border border-white/5 rounded-xl p-5 flex flex-col h-full min-h-[250px]">
                            <h4 class="text-sm font-bold text-white mb-4">Faixa Etária</h4>
                            <div v-if="dashboardData.demographics.idade && dashboardData.demographics.idade.length > 0" class="space-y-4 flex-1">
                                <div v-for="(item, idx) in dashboardData.demographics.idade" :key="idx">
                                    <div class="flex justify-between text-xs mb-1">
                                        <span class="text-secondary-300">{{ item.faixa }}</span>
                                        <span class="text-white font-bold">{{ item.qtd }}</span>
                                    </div>
                                     <div class="w-full h-2 bg-white/5 rounded-full overflow-hidden">
                                        <div class="h-full bg-purple-500 rounded-full" 
                                             :style="{ width: `${(item.qtd / getTotal(dashboardData.demographics.idade)) * 100}%` }">
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div v-else class="flex-1 flex items-center justify-center text-secondary/40 text-xs">
                                Sem dados de idade
                            </div>
                        </div>

                        <!-- PCD -->
                         <div class="bg-[#16161E] border border-white/5 rounded-xl p-5 flex flex-col justify-center h-full min-h-[250px]">
                            <h4 class="text-sm font-bold text-white mb-4 absolute top-5 left-5">PCD</h4>
                            <div v-if="getRealTotal(dashboardData.demographics.pcd) > 0" class="flex flex-col items-center justify-center flex-1">
                                <div class="text-6xl font-black text-white mb-2">
                                     {{ dashboardData.demographics.pcd.find((i:any) => i.label === 'true' || i.label === true)?.qtd || 0 }}
                                </div>
                                <p class="text-sm text-secondary font-bold uppercase tracking-wider">Pessoas com Deficiência</p> 
                                 <p class="text-xs text-secondary/50 mt-4">
                                    Total Inscritos: {{ getRealTotal(dashboardData.demographics.pcd) }}
                                 </p>
                            </div>
                             <div v-else class="flex-1 flex items-center justify-center text-secondary/40 text-xs">
                                Sem dados PCD
                            </div>
                        </div>

                    </div>
                </div>

            </div>
            
            <!-- EMPTY STATE -->
            <div v-else class="flex flex-col items-center justify-center py-20 opacity-50">
                 <div class="text-5xl mb-4">∅</div>
                 <p class="text-white font-medium">Nenhum dado encontrado para este período.</p>
            </div>
        </div>
        
        <!-- Sidebar Actions -->
        <template #sidebar>
            <div class="bg-div-15 rounded-xl p-5 border border-secondary/10">
                <h3 class="text-sm font-bold text-white mb-4">Ações Rápidas</h3>
                <div class="space-y-2">
                    <button class="w-full bg-[#16161E] hover:bg-white/5 border border-white/5 text-secondary hover:text-white text-xs font-bold py-3 px-4 rounded-lg transition-colors flex items-center justify-between group">
                        <span>Configurar Dashboard</span>
                        <svg class="w-4 h-4 opacity-50 group-hover:opacity-100" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                    </button>
                    <button class="w-full bg-[#16161E] hover:bg-white/5 border border-white/5 text-secondary hover:text-white text-xs font-bold py-3 px-4 rounded-lg transition-colors flex items-center justify-between group">
                        <span>Exportar Relatório</span>
                         <svg class="w-4 h-4 opacity-50 group-hover:opacity-100" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"></path></svg>
                    </button>
                </div>
            </div>
        </template>
    </NuxtLayout>
</template>
