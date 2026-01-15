<script setup lang="ts">
import { useToast } from '../../../composables/useToast'
import ModalMeusDocumentos from '../../components/ModalMeusDocumentos.vue'

definePageMeta({
    layout: false
})

const { showToast } = useToast()
const appStore = useAppStore()

// State
const processos = ref<any[]>([])
const isLoading = ref(true)
const showModal = ref(false)
const selectedProcesso = ref<any>(null)

// Computed Stats
const areaStats = computed(() => {
    const stats: Record<string, number> = {}
    processos.value.forEach(p => {
        const area = p.area_normalizada || 'Outros'
        stats[area] = (stats[area] || 0) + 1
    })
    return stats
})

// Fetch Processes via BFF
const fetchProcessos = async () => {
    isLoading.value = true
    try {
        const { data, error } = await useFetch('/api/aluno/processos')
        
        if (error.value) throw error.value

        processos.value = (data.value as any[]) || []
    } catch (e: any) {
        console.error('Error loading processes:', e)
        showToast('Erro ao carregar suas inscrições', { type: 'error' })
    } finally {
        isLoading.value = false
    }
}

// Lifecycle
onMounted(async () => {
    await appStore.refreshHash() // Ensure signed URLs work
    fetchProcessos()
})

// Handlers
const openDocumentModal = (processo: any) => {
    selectedProcesso.value = processo
    showModal.value = true
}

// Helpers
const formatDate = (dateString: string) => {
    if (!dateString) return '--/--/----'
    return new Date(dateString).toLocaleDateString('pt-BR')
}
</script>

<template>
  <NuxtLayout name="base">
    <div>
      <!-- Header Removed in previous step -->

      <!-- Loading -->
      <div v-if="isLoading" class="flex justify-center py-20">
          <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-primary"></div>
      </div>

      <!-- Empty State -->
      <div v-else-if="processos.length === 0" class="bg-div-15 rounded-xl p-8 text-center border border-white/5">
          <div class="text-5xl mb-4">📂</div>
          <h3 class="text-xl font-bold text-white mb-2">Nenhuma inscrição encontrada</h3>
          <p class="text-secondary-400 text-sm">Você ainda não se inscreveu em nenhum curso.</p>
          <NuxtLink to="/selecao/estudante" class="inline-block mt-4 px-6 py-2 bg-primary hover:bg-primary/90 text-white font-bold rounded-lg transition-colors">
              Ver Cursos Disponíveis
          </NuxtLink>
      </div>

      <!-- List -->
      <div v-else class="grid gap-3">
          <div 
              v-for="proc in processos" 
              :key="proc.id_processo"
              class="group bg-div-15 rounded-lg p-4 border border-white/5 hover:border-white/10 hover:bg-white/5 transition-all flex flex-col md:flex-row gap-4 items-start md:items-center justify-between"
          >
              <!-- Info Column -->
              <div class="flex-grow flex items-center gap-4">
                  <!-- Status Dot -->
                  <div 
                      class="w-1.5 h-12 rounded-full hidden md:block"
                      :class="proc.documentos_pendentes ? 'bg-red-500' : 'bg-emerald-500'"
                  ></div>

                  <div>
                      <div class="flex items-center gap-2 mb-2">
                          <span class="px-2 py-0.5 rounded bg-blue-500/10 text-blue-400 text-[10px] font-black uppercase tracking-wider border border-blue-500/20">
                              Inscrito
                          </span>
                          <span class="px-2 py-0.5 rounded bg-white/5 text-secondary-400 text-[10px] font-bold uppercase tracking-wider border border-white/10">
                              {{ proc.area_normalizada }}
                          </span>
                      </div>

                      <h3 class="text-sm md:text-base font-bold text-white leading-tight group-hover:text-primary transition-colors">
                          {{ proc.nome_curso }}
                      </h3>

                      <div class="flex flex-wrap gap-4 text-[10px] md:text-xs text-secondary-400 mt-1.5 opacity-60">
                           <span>Solicitado: <strong>{{ formatDate(proc.criado_em) }}</strong></span>
                           <span>Início: <strong>{{ formatDate(proc.dt_ini_curso) }}</strong></span>
                      </div>
                  </div>
              </div>

              <!-- Action Column -->
              <div class="flex items-center gap-3 w-full md:w-auto mt-2 md:mt-0">
                  <span 
                      v-if="proc.documentos_pendentes" 
                      class="text-[10px] font-bold text-red-400 uppercase tracking-wide md:hidden"
                  >
                      Pendente
                  </span>

                  <button 
                      @click="openDocumentModal(proc)"
                      class="ml-auto md:ml-0 px-4 py-1.5 rounded textxs font-bold transition-all flex items-center justify-center gap-2 whitespace-nowrap"
                      :class="proc.documentos_pendentes
                          ? 'bg-red-500 hover:bg-red-600 text-white shadow-lg shadow-red-500/20 text-xs'
                          : 'bg-white/5 hover:bg-white/10 text-white border border-white/10 hover:border-white/20 text-xs'"
                  >
                      {{ proc.documentos_pendentes ? 'Corrigir' : 'Ver Documentos' }}
                  </button>
              </div>
          </div>
      </div>

      <!-- Modal -->
      <ModalMeusDocumentos 
          :isOpen="showModal"
          :processo="selectedProcesso"
          @close="showModal = false"
      />
    </div>

    <!-- Sidebar Slot -->
    <template #sidebar>
        <!-- Widget: Instructions -->
        <div>
            <h4 class="text-[9px] font-black text-primary uppercase tracking-[0.2em] mb-4 flex items-center gap-2">
                <span class="w-1.5 h-1.5 rounded-full bg-primary"></span>
                Instruções
            </h4>
            
            <div class="space-y-4">
                <div class="bg-div-30/50 p-3 rounded-lg border border-secondary/5">
                    <p class="text-[11px] font-bold text-white mb-1 flex items-center gap-2">
                        <span class="w-4 h-4 rounded-full bg-secondary/20 flex items-center justify-center text-[9px]">1</span>
                        Verificar Inscrições
                    </p>
                    <p class="text-[10px] text-secondary leading-relaxed pl-6">
                        Use o botão <strong class="text-white">Ver Documentos</strong> para visualizar e conferir os arquivos que você já enviou.
                    </p>
                </div>

                <div class="bg-red-500/5 p-3 rounded-lg border border-red-500/10">
                    <p class="text-[11px] font-bold text-red-400 mb-1 flex items-center gap-2">
                        <span class="w-4 h-4 rounded-full bg-red-500/20 flex items-center justify-center text-[9px]">2</span>
                        Pendências
                    </p>
                    <p class="text-[10px] text-secondary leading-relaxed pl-6">
                        Caso tenha alguma pendência, você verá um botão <strong class="text-red-400">Corrigir</strong>. Basta clicar e reenviar o documento solicitado.
                    </p>
                </div>
            </div>
        </div>
        
        <div class="w-full h-[1px] bg-secondary/10 my-6"></div>

        <!-- Widget: Stats Dashboard -->
        <div>
            <h4 class="text-[9px] font-black text-secondary uppercase tracking-[0.2em] mb-4">
                Resumo por Área
            </h4>
            <!-- Stats Grid -->
            <div class="grid grid-cols-1 gap-2">
                <div v-for="(count, area) in areaStats" :key="area" class="bg-div-30 p-3 rounded-lg border border-secondary/5 flex items-center justify-between group hover:border-primary/20 transition-all">
                   <span class="text-[11px] font-bold text-secondary group-hover:text-primary transition-colors capitalize">{{ area }}</span>
                   <span class="text-md font-black text-white bg-background px-2 py-0.5 rounded border border-white/5">{{ count }}</span>
                </div>
            </div>
             <!-- Total -->
            <div class="mt-3 pt-3 border-t border-secondary/5 flex items-center justify-between text-xs">
                <span class="font-bold text-secondary">Total de Inscrições</span>
                <span class="font-black text-primary">{{ processos.length }}</span>
            </div>
        </div>
    </template>

  </NuxtLayout>
</template>
