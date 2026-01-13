<script setup lang="ts">
import { getAnoSemestre } from '../../../utils/seletivo';
import { useToast } from '../../../composables/useToast';
import ModalDadosCandidato from '../../components/ModalDadosCandidato.vue';

const client = useSupabaseClient();
const router = useRouter();
const appStore = useAppStore(); // Para renovar hash quando necessário
const { showToast } = useToast();

// --- STATE ---
const areas = ['Extensão', 'Regulares', 'Cursos Livres'];
const currentArea = ref('Extensão');
const isLoading = ref(false);
const limit = 20;

const route = useRoute();
const tipoCandidatura = computed(() => {
    const tipo = route.params.tipo as string;
    return (tipo === 'docente' || tipo === 'estudante') ? tipo : 'estudante'; // Default fallback
});

// Map display names to database values
const areaMap: Record<string, string> = {
    'Extensão': 'extensao',
    'Regulares': 'regulares',
    'Cursos Livres': 'cursos_livres'
};

// Filters State
const anoSemestre = ref(getAnoSemestre()); // Default format '25Is'
const selectedTurmaId = ref<string | null>(null);
const turmas = ref<any[]>([]);

// Search & Sort State (iniciam vazios/null)
const searchQuery = ref('');
const sortBy = ref<'nome_completo' | 'created_at'>('nome_completo');
const sortDirection = ref<'ASC' | 'DESC'>('ASC');

// Candidates State
const candidatos = ref<any[]>([]);
const pagination = ref({
    pagina_atual: 1,
    qtd_paginas: 0,
    qtd_total: 0
});

// Modal State
const showDataModal = ref(false);
const selectedCandidateForData = ref<any>(null);
const modalMode = ref<'dados' | 'documentos' | 'avaliar'>('dados');

// Confirmation Modal State
const confirmModal = ref({
    isOpen: false,
    title: '',
    message: '',
    type: 'info' as 'info' | 'danger',
    action: null as (() => Promise<void>) | null,
    isLoading: false
});

const handleEnrollTrigger = (candidato: any) => {
    const turma = turmas.value.find((t: any) => t.id_turma === selectedTurmaId.value);
    const cursoNome = turma ? turma.nome_curso_turno : 'Curso Selecionado';

    confirmModal.value = {
        isOpen: true,
        title: 'Confirmar Matrícula',
        message: `Você tem certeza que deseja Matricular o estudante <strong>${candidato.nome_completo}</strong> no curso <strong>${cursoNome}</strong>?`,
        type: 'info',
        isLoading: false,
        action: async () => {
             const { error } = await (client.rpc as any)('nxt_upsert_matricula', {
                 p_id_turma: selectedTurmaId.value,
                 p_id_user: candidato.id_user_expandido
             });
             
             if (error) throw error;
             
             showToast('Aluno matriculado com sucesso!', { type: 'info' });
             candidato.status_processo = 'Matriculado';
        }
    };
}

const handleDeleteTrigger = (candidato: any) => {
    confirmModal.value = {
        isOpen: true,
        title: 'Excluir Processo',
        message: `Você tem certeza que deseja Deletar o processo de <strong>${candidato.nome_completo}</strong>?<br/><br/><span class="text-red-400 font-bold">Essa ação não poderá ser desfeita.</span>`,
        type: 'danger',
        isLoading: false,
        action: async () => {
             const { error } = await (client.rpc as any)('nxt_delete_inscricao_processo', {
                 p_processo_id: candidato.id_processo
             });
             
             if (error) throw error;
             
             showToast('Processo removido com sucesso!', { type: 'info' });
             candidatos.value = candidatos.value.filter((c: any) => c.id_processo !== candidato.id_processo);
        }
    };
}

const confirmAction = async () => {
    if (!confirmModal.value.action) return;
    
    confirmModal.value.isLoading = true;
    try {
        await confirmModal.value.action();
        confirmModal.value.isOpen = false;
    } catch (e: any) {
        console.error('Error in confirm action:', e);
        showToast(e.message || 'Erro ao processar ação.', { type: 'error' });
    } finally {
        confirmModal.value.isLoading = false;
    }
};

// --- ACTIONS ---

const fetchTurmas = async () => {
    isLoading.value = true;
    try {
        // Cast rpc method to any to bypass strict type check for new function
        const { data, error } = await (client.rpc as any)('nxt_get_turmas_seletivo', {
            p_area: areaMap[currentArea.value], // Use mapped value
            p_ano_semestre: anoSemestre.value
        });

        if (error) {
            console.error('Error fetching turmas:', error);
            return;
        }

        // Combine both lists for the dropdown, or just use em_andamento by default?
        // Let's combine for now, but maybe prioritize 'em_andamento'
        const raw = data as any;
        const all = [...(raw.em_andamento || []), ...(raw.encerrados || [])];
        turmas.value = all;

        // Auto-select first if none selected or invalid
        if (all.length > 0) {
            if (!selectedTurmaId.value || !all.find((t: any) => t.id_turma === selectedTurmaId.value)) {
                selectedTurmaId.value = all[0].id_turma;
            }
        } else {
            selectedTurmaId.value = null;
        }

    } catch (e) {
        console.error(e);
    } finally {
        isLoading.value = false;
    }
};

const fetchCandidatos = async (page = 1) => {
    if (!selectedTurmaId.value) {
        candidatos.value = [];
        return;
    }

    isLoading.value = true;
    try {
        const { data, error } = await (client.rpc as any)('nxt_get_candidatos_processo_turma_v2', {
            p_id_turma: selectedTurmaId.value,
            p_pagina: page,
            p_limite: limit,
            p_tipo_candidatura: tipoCandidatura.value,
            p_busca: searchQuery.value.trim() || null,
            p_filtros: [],
            p_pcd: null,
            p_laudo: null,
            p_ordenar_por: sortBy.value,
            p_ordenar_como: sortDirection.value
        });

        if (error) throw error;

        const result = data as any;
        candidatos.value = result.itens || [];
        pagination.value = {
            pagina_atual: result.pagina_atual,
            qtd_paginas: result.qtd_paginas,
            qtd_total: result.qtd_total
        };

    } catch (e) {
        console.error('Error fetching candidates:', e);
    } finally {
        isLoading.value = false;
    }
};

// --- WATCHERS ---

// Renova hash quando área ou semestre mudam
watch([currentArea, anoSemestre], async () => {
    selectedTurmaId.value = null;
    await appStore.refreshHash();
    fetchTurmas();
});

// Renova hash quando turma muda
watch(selectedTurmaId, async () => {
    if (selectedTurmaId.value) {
        await appStore.refreshHash();
        fetchCandidatos(1);
    } else {
        candidatos.value = [];
    }
});

// Renova hash quando busca muda (onBlur)
watch(searchQuery, async () => {
    if (selectedTurmaId.value) {
        await appStore.refreshHash();
        fetchCandidatos(1);
    }
});

// Renova hash quando ordenação muda
watch([sortBy, sortDirection], async () => {
    if (selectedTurmaId.value) {
        await appStore.refreshHash();
        fetchCandidatos(1);
    }
});

// --- LIFECYCLE ---
onMounted(() => {
    fetchTurmas();
});

// --- HANDLERS ---
const handleCandidateUpdate = (payload: { id_processo: string, nota_total_processo: number }) => {
    const index = candidatos.value.findIndex(c => c.id_processo === payload.id_processo);
    if (index !== -1) {
        candidatos.value[index].nota_total_processo = payload.nota_total_processo;
        if (selectedCandidateForData.value && selectedCandidateForData.value.id_processo === payload.id_processo) {
             selectedCandidateForData.value.nota_total_processo = payload.nota_total_processo;
        }
    }
}

const handleAction = async (action: string, candidato: any) => {
    // Renova hash antes de executar ação (garante fotos/dados válidos)
    await appStore.refreshHash();
    
    console.log('Action:', action, candidato);
    
    if (action === 'dados') {
        selectedCandidateForData.value = candidato;
        modalMode.value = 'dados';
        showDataModal.value = true;
        return;
    }

    if (action === 'documentos') {
        selectedCandidateForData.value = candidato;
        modalMode.value = 'documentos';
        showDataModal.value = true;
        return;
    }

    if (action === 'avaliar') {
        selectedCandidateForData.value = candidato;
        modalMode.value = 'avaliar';
        showDataModal.value = true;
        return;
    }

    if (action === 'matricular') {
        handleEnrollTrigger(candidato);
        return;
    }

    if (action === 'deletar') {
        handleDeleteTrigger(candidato);
        return;
    }
    
    // TODO: Implement specific actions
    alert(`Action ${action} clicked for ${candidato.nome_completo}`);
};

const toggleSortDirection = () => {
    sortDirection.value = sortDirection.value === 'ASC' ? 'DESC' : 'ASC';
};

const previousPage = async () => {
    if (pagination.value.pagina_atual > 1) {
        await appStore.refreshHash(); // Renova hash ao mudar página
        fetchCandidatos(pagination.value.pagina_atual - 1);
    }
};

const nextPage = async () => {
    if (pagination.value.pagina_atual < pagination.value.qtd_paginas) {
        await appStore.refreshHash(); // Renova hash ao mudar página
        fetchCandidatos(pagination.value.pagina_atual + 1);
    }
};
</script>

<template>
  <NuxtLayout name="base">
    <!-- Main Container with bg-div-15 -->
    <div class="bg-div-15 rounded-xl p-6 md:p-8">
        <!-- TABS (Area Selection) - Outside controls island -->
        <div class="flex items-center gap-6 border-b border-secondary/10 mb-6">
            <button 
                v-for="area in areas" 
                :key="area"
                @click="currentArea = area"
                class="text-sm font-bold pb-3 relative transition-colors text-secondary hover:text-primary"
                :class="{ 'text-primary': currentArea === area }"
            >
                {{ area }}
                <span v-if="currentArea === area" class="absolute bottom-[-1px] left-0 w-full h-0.5 bg-primary rounded-full"></span>
            </button>
        </div>

        <!-- CONTROLS ISLAND (nested bg-div-15) -->
        <div class="bg-div-15 rounded-xl p-4 md:p-6 mb-6 border border-secondary/5">
            <!-- FILTERS -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-3 mb-4">
                <!-- Semestre -->
                <div>
                    <label class="block text-xs text-secondary-600 mb-1.5">Período</label>
                    <select v-model="anoSemestre" class="w-full bg-[#16161E] border border-white/10 text-white text-sm rounded-lg focus:ring-primary focus:border-primary p-3">
                        <option :value="getAnoSemestre(undefined, -1)">{{ getAnoSemestre(undefined, -1) }}</option>
                        <option :value="getAnoSemestre()">{{ getAnoSemestre() }} (Atual)</option>
                        <option :value="getAnoSemestre(undefined, 1)">{{ getAnoSemestre(undefined, 1) }}</option>
                    </select>
                </div>

                <!-- Turma -->
                <div>
                    <label class="block text-xs text-secondary-600 mb-1.5">Turma</label>
                    <select v-model="selectedTurmaId" class="w-full bg-[#16161E] border border-white/10 text-white text-sm rounded-lg focus:ring-primary focus:border-primary p-3">
                        <option :value="null" disabled>Selecione uma turma...</option>
                        <option v-for="t in turmas" :key="t.id_turma" :value="t.id_turma">
                            {{ t.nome_curso_turno }}
                        </option>
                    </select>
                </div>
            </div>

            <!-- SEARCH & SORT -->
            <div class="flex flex-col md:flex-row gap-3">
                <!-- Search -->
                <div class="flex-grow">
                    <label class="block text-xs text-secondary-600 mb-1.5">Buscar por nome</label>
                    <input 
                        v-model="searchQuery"
                        @blur="searchQuery = searchQuery.trim()"
                        type="text"
                        placeholder="Digite o nome do candidato..."
                        class="w-full bg-[#16161E] border border-white/10 text-white text-sm rounded-lg focus:ring-primary focus:border-primary p-3 placeholder:text-gray-600"
                    />
                </div>

                <!-- Sort -->
                <div class="flex-shrink-0">
                    <label class="block text-xs text-secondary-600 mb-1.5">Ordenar por</label>
                    <div class="flex items-center gap-1.5 bg-[#16161E] border border-white/10 rounded-lg px-3 h-12">
                        <!-- Radio Options -->
                        <div class="flex gap-3">
                            <label class="flex items-center gap-1.5 cursor-pointer text-xs text-gray-400 hover:text-white transition-colors">
                                <input 
                                    type="radio" 
                                    v-model="sortBy" 
                                    value="nome_completo"
                                    class="w-3.5 h-3.5 m-0 text-primary bg-transparent border-gray-600 focus:ring-primary focus:ring-offset-0"
                                />
                                <span>Nome</span>
                            </label>
                            <label class="flex items-center gap-1.5 cursor-pointer text-xs text-gray-400 hover:text-white transition-colors">
                                <input 
                                    type="radio" 
                                    v-model="sortBy" 
                                    value="created_at"
                                    class="w-3.5 h-3.5 m-0 text-primary bg-transparent border-gray-600 focus:ring-primary focus:ring-offset-0"
                                />
                                <span>Data</span>
                            </label>
                        </div>

                        <!-- Divider -->
                        <div class="w-px h-4 bg-white/10"></div>

                        <!-- Sort Direction Toggle -->
                        <button 
                            @click="toggleSortDirection"
                            class="w-6 h-6 flex items-center justify-center rounded hover:bg-white/10 text-gray-400 hover:text-white transition-all"
                            :title="sortDirection === 'ASC' ? 'Ordem Crescente' : 'Ordem Decrescente'"
                        >
                            <svg v-if="sortDirection === 'ASC'" class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4h13M3 8h9m-9 4h6m4 0l4-4m0 0l4 4m-4-4v12"></path>
                            </svg>
                            <svg v-else class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4h13M3 8h9m-9 4h9m5-4v12m0 0l-4-4m4 4l4-4"></path>
                            </svg>
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- CONTENT AREA -->
        
        <!-- Loading -->
        <div v-if="isLoading" class="flex justify-center py-20">
            <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-primary"></div>
        </div>

        <!-- Empty State -->
        <div v-else-if="candidatos.length === 0" class="flex flex-col items-center justify-center py-16 md:py-20 text-center opacity-50">
            <div class="text-5xl md:text-6xl mb-4">📂</div>
            <p class="text-lg md:text-xl font-medium text-white">Nenhum candidato encontrado</p>
            <p class="text-secondary-400 text-xs md:text-sm mt-1">Selecione outra turma ou área para visualizar inscrições.</p>
        </div>

        <!-- List -->
        <div v-else class="space-y-3 md:space-y-4">
            <CandidateCard 
                v-for="candidato in candidatos" 
                :key="candidato.id_processo"
                :candidato="candidato"
                @action="handleAction"
            />
        </div>

        <!-- PAGINATION -->
        <div v-if="candidatos.length > 0" class="flex flex-col md:flex-row items-center justify-between gap-3 mt-6 md:mt-8 pt-4 border-t border-white/5">
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

    <!-- Dashboard in Sidebar Slot -->
    <template #sidebar>
        <CandidateDashboard 
            :candidatos="candidatos"
            :totalCount="pagination.qtd_total"
        />
    </template>

    <!-- Modals -->
    <ModalDadosCandidato
        :isOpen="showDataModal"
        :candidato="selectedCandidateForData"
        :area="areaMap[currentArea] || ''"
        :tipoProcesso="'seletivo'"
        :tipoCandidatura="tipoCandidatura"
        :mode="modalMode"
        @close="showDataModal = false"
        @update-candidate="handleCandidateUpdate"
    />

    <!-- CONFIRMATION MODAL -->
    <div v-if="confirmModal.isOpen" class="relative z-50" aria-labelledby="modal-title" role="dialog" aria-modal="true">
        <div class="fixed inset-0 bg-black/80 backdrop-blur-sm transition-opacity"></div>

        <div class="fixed inset-0 z-10 overflow-y-auto">
            <div class="flex min-h-full items-center justify-center p-4 text-center sm:p-0">
                <div class="relative transform overflow-hidden rounded-2xl bg-[#16161E] border border-white/10 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg p-6">
                    
                    <div class="flex items-center gap-4 mb-4">
                        <div class="w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0" :class="confirmModal.type === 'danger' ? 'bg-red-500/10' : 'bg-emerald-500/10'">
                            <svg v-if="confirmModal.type === 'danger'" class="w-6 h-6 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path></svg>
                            <svg v-else class="w-6 h-6 text-emerald-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                        </div>
                        <h3 class="text-xl font-bold text-white leading-6">{{ confirmModal.title }}</h3>
                    </div>

                    <div class="mt-2">
                        <p class="text-sm text-secondary-300" v-html="confirmModal.message"></p>
                    </div>

                    <div class="mt-6 flex gap-3 justify-end">
                        <button 
                            type="button" 
                            class="inline-flex justify-center rounded-lg border border-white/10 bg-white/5 px-4 py-2 text-sm font-semibold text-white hover:bg-white/10 focus:outline-none focus:ring-2 focus:ring-secondary-500"
                            @click="confirmModal.isOpen = false"
                            :disabled="confirmModal.isLoading"
                        >
                            Cancelar
                        </button>
                        <button 
                            type="button" 
                            class="inline-flex justify-center rounded-lg px-4 py-2 text-sm font-bold text-white shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
                            :class="confirmModal.type === 'danger' 
                                ? 'bg-red-500 hover:bg-red-600 focus:ring-red-500' 
                                : 'bg-emerald-500 hover:bg-emerald-600 focus:ring-emerald-500'"
                            @click="confirmAction"
                            :disabled="confirmModal.isLoading"
                        >
                            <svg v-if="confirmModal.isLoading" class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                            {{ confirmModal.type === 'danger' ? 'Sim, remover' : 'Sim, matricular' }}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>
  </NuxtLayout>
</template>

<style scoped>
.hide-scrollbar::-webkit-scrollbar {
    display: none;
}
.hide-scrollbar {
    -ms-overflow-style: none;
    scrollbar-width: none;
}
</style>
