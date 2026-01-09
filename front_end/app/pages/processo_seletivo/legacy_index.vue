<script setup lang="ts">
import { formatDate, formatDayMonth } from '@/utils/date'

definePageMeta({
  layout: 'landing',
  title: 'Cursos Disponíveis'
})

// --- Tipos ---
type FilterValue = 'estudante' | 'docente'

interface FilterOption {
  label: string
  value: FilterValue
  icon: string
}

interface ApiResponse {
  items: any[]
  source: string
}

// --- Estado ---
const tipoCandidatura = ref<FilterValue>('estudante')
const areaSelecionada = ref<string>('extensao')

// --- Opções de Filtro ---
const filtersCandidatura: FilterOption[] = [
  { label: 'Estudante', value: 'estudante', icon: '🎓' },
  { label: 'Docente', value: 'docente', icon: '👨‍🏫' }
]

const filtersArea = [
  { label: 'Extensão', value: 'extensao' },
  { label: 'Regulares', value: 'regulares' },
  { label: 'Cursos Livres', value: 'cursos_livres' }
]

// --- BFF Call ---
const { data, pending, error, refresh } = await useFetch<ApiResponse>('/api/cursos/disponiveis', {
  query: computed(() => ({
    tipo_candidatura: tipoCandidatura.value
  })),
  watch: [tipoCandidatura]
})

// --- Computados ---
const cursosFiltrados = computed(() => {
  const items = data.value?.items || []
  
  if (!items.length) return []

  // Filtro de Área
  return items.filter((curso: any) => {
    if (curso.area_curso_int) {
        return curso.area_curso_int.toLowerCase() === areaSelecionada.value.toLowerCase()
    }

    const areaCurso = (curso.area_curso || '').toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    const areaFiltro = areaSelecionada.value.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    
    if (areaFiltro === 'cursos_livres' && areaCurso.includes('livre')) return true
    
    return areaCurso.includes(areaFiltro)
  })
})

const handleInscricao = (curso: any) => {
  console.log('Iniciar inscrição para:', curso)
}

const formatDiasSemana = (dias: string[] | string | null): string => {
    if (!dias) return 'Dias a definir'
    if (Array.isArray(dias)) return dias.join(' | ')
    return dias
}
</script>

<template>
  <div class="relative min-h-full">
    
    <!-- Filter Bar (Sticky inside Main) -->
    <div class="bg-div-15 backdrop-blur-md border-b border-secondary/5 py-3 px-4 lg:px-6 sticky top-0 z-30 transition-all shadow-sm">
       <div class="flex flex-col md:flex-row items-center justify-between gap-4">
         
         <!-- Filter: Candidatura -->
         <div class="flex p-1 bg-div-30 rounded-lg border border-secondary/10 shadow-inner">
            <button 
              v-for="opt in filtersCandidatura" 
              :key="opt.value"
              @click="tipoCandidatura = opt.value"
              class="flex items-center gap-1.5 px-3 py-1.5 rounded-md text-[10px] font-bold transition-all relative"
              :class="tipoCandidatura === opt.value ? 'bg-background text-primary shadow-sm ring-1 ring-secondary/5' : 'text-secondary hover:text-text'"
            >
               <span class="opacity-70 grayscale text-[12px]">{{ opt.icon }}</span>
               <span>{{ opt.label }}</span>
            </button>
         </div>

         <!-- Filter: Área -->
         <div class="flex items-center gap-1 overflow-x-auto no-scrollbar max-w-full pb-1 md:pb-0">
            <button
               v-for="area in filtersArea"
               :key="area.value"
               @click="areaSelecionada = area.value"
               class="px-3 py-1.5 text-[10px] uppercase tracking-widest font-bold transition-all border-b-2 whitespace-nowrap"
               :class="areaSelecionada === area.value ? 'border-primary text-primary' : 'border-transparent text-secondary hover:text-text hover:bg-div-30 rounded-t'"
            >
               {{ area.label }}
            </button>
         </div>

       </div>
    </div>

    <!-- Main Content -->
    <div class="px-4 lg:px-6 py-6 flex flex-col items-start gap-6">
      
      <!-- Loading State -->
      <div v-if="pending" class="w-full py-20 flex flex-col items-center justify-center opacity-50">
           <div class="w-8 h-8 border-2 border-primary/20 border-t-primary rounded-full animate-spin mb-4" />
           <p class="text-[10px] font-bold uppercase text-secondary tracking-widest">Carregando oportunidades...</p>
      </div>

      <!-- Error State -->
      <div v-else-if="error" class="w-full bg-red-50 text-red-600 p-4 rounded-lg border border-red-100 flex items-center gap-3">
           <div class="text-xl">⚠️</div>
           <div>
             <h3 class="font-bold text-xs">Erro ao carregar cursos</h3>
             <p class="text-[10px] opacity-80">Não foi possível buscar as turmas disponíveis.</p>
             <button @click="() => refresh()" class="mt-1 text-[10px] font-bold underline">Recarregar</button>
           </div>
      </div>

      <!-- Empty State -->
      <div v-else-if="cursosFiltrados.length === 0" class="w-full py-20 text-center">
          <div class="inline-block p-4 rounded-full bg-div-15 mb-3 text-2xl grayscale opacity-50">📭</div>
          <h3 class="text-sm font-bold text-text">Nenhum curso encontrado</h3>
          <p class="text-[11px] text-secondary max-w-xs mx-auto mt-1">
            Não encontramos turmas abertas para <strong>{{ filtersArea.find(a => a.value === areaSelecionada)?.label }}</strong>.
          </p>
      </div>

      <!-- Grid de Cursos -->
      <div v-else class="w-full grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          <div 
            v-for="curso in cursosFiltrados" 
            :key="curso.id"
            class="group bg-background rounded-lg border border-secondary/10 p-4 hover:border-primary/30 hover:shadow-lg hover:shadow-primary/5 transition-all duration-300 flex flex-col relative"
          >
            <!-- Header Compacto -->
            <div class="flex justify-between items-start mb-3">
                <span class="inline-block px-1.5 py-0.5 rounded text-[8px] font-black uppercase tracking-wider bg-div-15 text-primary border border-secondary/5">
                    {{ curso.area_curso_int || curso.area_curso || 'Curso' }}
                </span>
                
                <!-- Big Date Minimal -->
                <div class="flex flex-col items-end leading-none text-primary/10 group-hover:text-primary/20 transition-colors select-none">
                    <span class="text-3xl font-black -mt-2 -mr-1 tracking-tighter">{{ formatDayMonth(curso.dt_ini_curso).split(' ')[0] }}</span>
                    <span class="text-[8px] font-bold uppercase tracking-widest">{{ formatDayMonth(curso.dt_ini_curso).split(' ')[1] }}</span>
                </div>
            </div>

            <h3 class="text-sm font-bold text-text leading-tight group-hover:text-primary transition-colors mb-3 line-clamp-2 min-h-[2.5rem]">
                {{ curso.nome_curso }}
            </h3>

            <!-- Info Lines -->
            <div class="space-y-1.5 mb-4">
                 <div class="flex items-center gap-2 text-[10px] text-secondary">
                    <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="opacity-70"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
                    <span class="font-medium truncate">{{ curso.turno || '---' }}</span>
                    <span class="text-secondary/30">|</span>
                    <span class="font-medium">{{ curso.qtd_horas_total || '--' }}h</span>
                 </div>
                 <div class="flex items-center gap-2 text-[10px] text-secondary">
                     <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="opacity-70"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
                     <span class="font-medium uppercase tracking-tight truncate max-w-[180px]" :title="formatDiasSemana(curso.dias_semana_array || curso.dias_semana)">
                        {{ formatDiasSemana(curso.dias_semana_array || curso.dias_semana) }}
                     </span>
                 </div>
            </div>

            <!-- Footer: Dates & Button -->
            <div class="mt-auto pt-3 border-t border-secondary/5 flex items-center justify-between gap-3">
                <div class="flex flex-col">
                    <span class="text-[8px] font-bold text-secondary/50 uppercase tracking-wider mb-0.5">Inscrições</span>
                    <span class="text-[10px] font-bold text-text bg-div-15 px-1.5 py-0.5 rounded border border-secondary/5">
                        {{ formatDate(curso.dt_ini_inscri, 'dd/MM') }} - {{ formatDate(curso.dt_fim_inscri, 'dd/MM') }}
                    </span>
                </div>

                <button 
                  @click="handleInscricao(curso)"
                  class="bg-primary text-white font-bold px-4 py-2 rounded-md text-[10px] uppercase tracking-wider hover:bg-primary/90 hover:shadow-md hover:shadow-primary/10 transition-all active:scale-[0.98]"
               >
                 Inscrever
               </button>
            </div>
          </div>
      </div>

    </div>
  </div>
</template>

<style>
.no-scrollbar::-webkit-scrollbar {
  display: none;
}
.no-scrollbar {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
</style>
