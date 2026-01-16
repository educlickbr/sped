<script setup lang="ts">
import { getAnoSemestre } from '../../../utils/seletivo';
import { useAppStore } from '~/stores/app';

const store = useAppStore();
const hashBase = computed(() => store.hash_base || '');

// State
const activeTab = ref('alunos'); // alunos (only tab for carometro)
const anoSemestre = ref(getAnoSemestre());
const isLoading = ref(false);
const isLoadingAlunos = ref(false);

// Data
const turmas = ref<any[]>([]);
const alunos = ref<any[]>([]);
const dashboardStats = ref<Record<string, any> | undefined>(undefined);
const pagination = ref({
    pagina_atual: 1,
    qtd_paginas: 0,
    qtd_total: 0
});
const limit = 20;

// Filters
const filters = ref({
    turno: '',
    area: '',
    curso: '', // This will hold the turma ID actually
    busca: ''
    // Status REMOVED - Always 'Ativo'
});

// Options
const turnos = ['Matutino', 'Vespertino', 'Noturno'];
const areas = ['Regulares', 'Cursos Livres', 'Extensão'];

// Fetch Turmas
const fetchTurmas = async () => {
    isLoading.value = true;
    try {
        const data: any = await $fetch('/api/matriculas/turmas', {
            params: {
                ano_semestre: anoSemestre.value,
                turno: filters.value.turno || null,
                area: filters.value.area || null
            }
        });
        
        turmas.value = data.turmas || [];

    } catch (e) {
        console.error('Erro ao buscar turmas:', e);
    } finally {
        isLoading.value = false;
        // Fetch Alunos when turmas are loaded (or emptied)
        fetchAlunos(1);
        fetchStats();
    }
};

// Fetch Stats
const fetchStats = async () => {
    try {
        const data: any = await $fetch('/api/matriculas/stats', {
            params: {
                ano_semestre: anoSemestre.value,
                id_turma: filters.value.curso || null, 
                area: !filters.value.curso ? (filters.value.area || null) : null,
                turno: !filters.value.curso ? (filters.value.turno || null) : null,
                busca: filters.value.busca || null,
                status: 'Ativa' // HARDCODED
            }
        });
        dashboardStats.value = data;
    } catch (e) {
        console.error('Erro ao buscar estatísticas:', e);
    }
};

// Fetch Alunos
const fetchAlunos = async (page = 1) => {
    isLoadingAlunos.value = true;
    try {
        const data: any = await $fetch('/api/matriculas/alunos', {
            params: {
                ano_semestre: anoSemestre.value,
                // If filters.curso is set, use it. If not, use filters.area/turno context
                id_turma: filters.value.curso || null, 
                area: !filters.value.curso ? (filters.value.area || null) : null, // Only send area if no specific course selected
                turno: !filters.value.curso ? (filters.value.turno || null) : null, // Only send turno if no specific course selected
                
                busca: filters.value.busca || null,
                status: 'Ativa', // HARDCODED
                page: page,
                limit: limit
            }
        });

        alunos.value = data.alunos || [];
        // Update pagination from response
        if (data.paginacao) {
             pagination.value = {
                pagina_atual: data.paginacao.pagina_atual,
                qtd_paginas: data.paginacao.qtd_paginas,
                qtd_total: data.paginacao.qtd_total
            };
        } else {
             // Fallback if backend doesn't return pagination object structure yet
             // Assuming data.total might exist or just length
             pagination.value = {
                pagina_atual: page,
                qtd_paginas: Math.ceil((data.total || alunos.value.length) / limit),
                qtd_total: data.total || alunos.value.length
            };
        }

    } catch (e) {
        console.error('Erro ao buscar alunos:', e);
    } finally {
        isLoadingAlunos.value = false;
    }
};

// ACTIONS
const previousPage = async () => {
    if (pagination.value.pagina_atual > 1) {
        await store.refreshHash();
        fetchAlunos(pagination.value.pagina_atual - 1);
    }
};

const nextPage = async () => {
    if (pagination.value.pagina_atual < pagination.value.qtd_paginas) {
        await store.refreshHash();
        fetchAlunos(pagination.value.pagina_atual + 1);
    }
};

// Watchers
watch([anoSemestre, () => filters.value.turno, () => filters.value.area], async () => {
    await store.refreshHash();
    fetchTurmas();
});

watch(() => filters.value.curso, async () => {
    await store.refreshHash();
    fetchAlunos(1);
    fetchStats();
});

// Debounced Search
let searchTimeout: any;
watch(() => filters.value.busca, () => {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(async () => {
        await store.refreshHash();
        fetchAlunos(1);
        fetchStats();
    }, 500);
});

onMounted(() => {
    fetchTurmas();
});
</script>

<template>
    <NuxtLayout name="base">
        <div class="bg-transparent md:bg-div-15 rounded-none md:rounded-xl p-0 md:p-8 flex-1 w-full">
            
            <!-- HEADER / TABS -->
            <div class="flex flex-col md:flex-row items-center justify-between gap-4 mb-4">
                 <!-- Title for Carômetro instead of Tabs -->
                 <h2 class="text-xl font-bold text-white flex items-center gap-2">
                    <svg class="w-6 h-6 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect><circle cx="8.5" cy="8.5" r="1.5"></circle><polyline points="21 15 16 10 5 21"></polyline></svg>
                    Carômetro
                 </h2>

                <!-- Global Year Select -->
                <div class="relative w-full md:w-48">
                    <select v-model="anoSemestre" class="w-full bg-[#16161E] border border-secondary/10 text-white text-xs rounded-lg focus:ring-1 focus:ring-primary focus:border-primary p-2.5 pr-8 outline-none cursor-pointer appearance-none bg-[url('data:image/svg+xml;charset=utf-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20fill%3D%22none%22%20viewBox%3D%220%200%2020%2020%22%3E%3Cpath%20stroke%3D%22%236B7280%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22round%22%20stroke-width%3D%221.5%22%20d%3D%22M6%208l4%204%204-4%22%2F%3E%3C%2Fsvg%3E')] bg-[length:1.25rem_1.25rem] bg-no-repeat bg-[right_0.5rem_center]">
                        <option :value="getAnoSemestre(undefined, -1)">{{ getAnoSemestre(undefined, -1) }}</option>
                        <option :value="getAnoSemestre()">{{ getAnoSemestre() }} (Atual)</option>
                        <option :value="getAnoSemestre(undefined, 1)">{{ getAnoSemestre(undefined, 1) }}</option>
                    </select>
                </div>
            </div>
            
            <p class="text-xs text-secondary/70 mb-8">Visualização de alunos com matrícula ativa.</p>

            <!-- FILTER BAR (2 Rows, Grid 12) -->
            <div class="bg-[#16161E] border border-white/5 rounded-xl p-4 mb-6">
                <!-- Label -->
                <h4 class="text-[10px] font-bold text-secondary uppercase tracking-wider mb-3 flex items-center gap-2">
                    <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z"></path></svg>
                    Filtros de Busca
                </h4>

                <div class="space-y-3">
                    <!-- Row 1: Area | Curso | Turno -->
                    <div class="grid grid-cols-1 md:grid-cols-12 gap-3">
                         <!-- Area -->
                        <div class="md:col-span-3">
                            <select v-model="filters.area" class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:border-primary focus:outline-none appearance-none h-10">
                                <option value="">Todas Áreas</option>
                                <option v-for="area in areas" :key="area" :value="area">{{ area }}</option>
                            </select>
                        </div>

                         <!-- Curso -->
                        <div class="md:col-span-6 cursor-pointer relative">
                             <select v-model="filters.curso" class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:border-primary focus:outline-none appearance-none h-10 truncate pr-8" :disabled="isLoading">
                                <option value="" disabled>Selecione um Curso/Turma</option>
                                <option v-for="t in turmas" :key="t.id" :value="t.id">
                                    {{ t.nome_curso }} - {{ t.cod_turma }} ({{ t.turno }})
                                </option>
                            </select>
                             <div v-if="isLoading" class="absolute right-3 top-3">
                                <svg class="animate-spin h-4 w-4 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                            </div>
                        </div>

                         <!-- Turno -->
                        <div class="md:col-span-3">
                            <select v-model="filters.turno" class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:border-primary focus:outline-none appearance-none h-10">
                                <option value="">Todos Turnos</option>
                                <option value="Matutino">Matutino</option>
                                <option value="Vespertino">Vespertino</option>
                                <option value="Noturno">Noturno</option>
                            </select>
                        </div>
                    </div>

                    <!-- Row 2: Search (Full Width) -->
                    <div class="grid grid-cols-1 md:grid-cols-12 gap-3">
                         <!-- Search -->
                        <div class="md:col-span-12">
                             <input 
                                v-model="filters.busca"
                                type="text" 
                                placeholder="Buscar por nome do aluno..." 
                                class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:border-primary focus:outline-none placeholder-secondary/50 h-10"
                            />
                        </div>
                    </div>
                </div>
            </div>

            <!-- CONTENT AREA -->
            <div class="space-y-4">
                
                <!-- Loading State -->
                <div v-if="isLoadingAlunos" class="flex flex-col items-center justify-center py-20">
                     <svg class="animate-spin h-8 w-8 text-primary mb-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                     <p class="text-sm text-secondary">Carregando alunos...</p>
                </div>

                <!-- Empty State -->
                <div v-else-if="alunos.length === 0" class="flex flex-col items-center justify-center py-20 opacity-50 border border-dashed border-white/10 rounded-xl">
                    <div class="text-4xl mb-4 text-secondary/50">
                        <svg class="w-16 h-16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"></path></svg>
                    </div>
                    <p class="text-white font-medium">Nenhum aluno encontrado</p>
                    <p class="text-xs text-secondary mt-1">Verifique os filtros ou selecione outra turma.</p>
                </div>

                <!-- Student List (Card Layout) -->
                <div v-else class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
                    <div v-for="aluno in alunos" :key="aluno.id" class="bg-[#16161E] border border-white/5 rounded-xl flex md:overflow-visible overflow-hidden hover:border-primary/30 transition-colors group relative min-h-[120px]">
                        
                        <!-- Left: Full Height Photo -->
                        <div class="w-28 relative flex-shrink-0 bg-white/5 border-r border-white/5 group/photo hover:z-50">
                                <img 
                                v-if="aluno.foto_resposta && hashBase" 
                                :src="hashBase + aluno.foto_resposta" 
                                class="absolute inset-0 w-full h-full object-cover transition-all duration-300 group-hover/photo:scale-[1.8] group-hover/photo:translate-x-14 group-hover/photo:shadow-[0_0_30px_rgba(0,0,0,0.5)] z-10 rounded-l-xl md:rounded-lg"
                                alt="Foto"
                                @error="(e: any) => e.target.style.display = 'none'"
                            />
                            <div v-else class="absolute inset-0 flex flex-col items-center justify-center text-xs font-bold text-secondary bg-black/20">
                                <span class="text-2xl mb-1">{{ aluno.nome?.charAt(0) }}{{ aluno.sobrenome?.charAt(0) }}</span>
                                <span class="text-[9px] opacity-50">Sem Foto</span>
                            </div>
                        </div>

                        <!-- Right: Info (Simplified) -->
                        <div class="flex-1 p-3 flex flex-col justify-center min-w-0 z-10 gap-2 relative">
                            
                            <!-- Main Info Block -->
                            <div class="space-y-1">
                                <!-- Name & Email -->
                                <div class=""> 
                                    <h5 class="text-sm font-bold text-white truncate leading-tight" :title="aluno.nome + ' ' + aluno.sobrenome">
                                        {{ aluno.nome }} {{ aluno.sobrenome }}
                                    </h5>
                                    <p class="text-[10px] text-secondary truncate">{{ aluno.email }}</p>
                                </div>

                                <!-- Nome Social (if any) -->
                                <div v-if="aluno.nome_social" class="flex items-center gap-1.5">
                                    <span class="text-[9px] text-secondary uppercase tracking-wider font-bold">Social:</span>
                                    <span class="text-[10px] text-white/80 font-medium truncate">{{ aluno.nome_social }}</span>
                                </div>

                                <!-- Curso & Turno + RA -->
                                <div class="grid grid-cols-2 gap-x-2 gap-y-1 mt-1.5">
                                    <!-- Curso -->
                                    <div class="col-span-2">
                                         <p class="text-[9px] text-secondary uppercase tracking-wider font-bold mb-0.5">Curso</p>
                                         <p class="text-[10px] text-white font-medium truncate" :title="aluno.nome_curso_turno || aluno.nome_curso">{{ aluno.nome_curso }}</p>
                                    </div>

                                    <!-- Turno -->
                                    <div class="flex items-end justify-between pr-2">
                                        <div>
                                            <p class="text-[9px] text-secondary uppercase tracking-wider font-bold mb-0.5">Turno</p>
                                            <p class="text-[10px] text-white font-medium">{{ aluno.turno }}</p>
                                        </div>
                                    </div>

                                    <!-- RA -->
                                    <div>
                                         <p class="text-[9px] text-secondary uppercase tracking-wider font-bold mb-0.5">RA</p>
                                         <p class="text-[10px] text-white font-medium font-mono">{{ aluno.ra || aluno.ra_legado || '---' }}</p>
                                    </div>
                                </div>
                            </div>
                        </div>

                    </div>
                </div>

                <!-- PAGINATION -->
                <div v-if="alunos.length > 0" class="flex flex-col md:flex-row items-center justify-between gap-3 mt-6 pt-4 border-t border-white/5">
                    <span class="text-xs md:text-sm text-secondary-500 order-2 md:order-1">
                        <span class="font-medium text-white">{{ (pagination.pagina_atual - 1) * limit + 1 }}</span> a <span class="font-medium text-white">{{ Math.min(pagination.pagina_atual * limit, pagination.qtd_total) }}</span> de <span class="font-medium text-white">{{ pagination.qtd_total }}</span>
                    </span>
                    <div class="flex gap-2 order-1 md:order-2">
                        <button 
                            @click="previousPage" 
                            :disabled="pagination.pagina_atual === 1"
                            class="px-4 py-2 text-sm font-medium text-white bg-white/5 border border-white/10 rounded-lg hover:bg-white/10 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                        >
                            Anterior
                        </button>
                        <button 
                            @click="nextPage" 
                            :disabled="pagination.pagina_atual >= pagination.qtd_paginas"
                            class="px-4 py-2 text-sm font-medium text-white bg-white/5 border border-white/10 rounded-lg hover:bg-white/10 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                        >
                            Próxima
                        </button>
                    </div>
                </div>
            </div>

        </div>

        <template #sidebar>
             <CandidateDashboard 
                :candidatos="alunos"
                :totalCount="pagination.qtd_total"
                :statsData="dashboardStats"
            />
        </template>
    </NuxtLayout>
</template>
