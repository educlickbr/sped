<script setup lang="ts">
import { formatDate } from '@/utils/date'

definePageMeta({
  // layout: 'base', // Using explicit NuxtLayout in template
  title: 'Processo Seletivo - EduSelect'
})

const user = useSupabaseUser()
// Define cookie type explicitly to allow object
const redirectCookie = useCookie<any>('redirect_after_login')


// --- Tipos & Interface ---
type FilterRole = 'estudante' | 'docente'
type FilterCategory = 'extensao' | 'regulares' | 'cursos_livres'

// Interface da API
interface ApiResponse {
  items: any[]
  source: string
}

// Interface mapeada para o Frontend
interface MappedCourse {
  id: string
  title: string
  description: string
  hours: number | string
  mode: string
  status: 'Open' | 'Closed' | 'Waitlist'
  image: string
  role: FilterRole
  category: string
  rawDates: {
    start: string
    end: string
    startCourse: string
    endCourse: string
  }
  weekDays: string[]
}

// --- Estado ---
const selectedRole = ref<FilterRole>('estudante') // equivalente a tipoCandidatura
const selectedCategory = ref<FilterCategory>('extensao') // equivalente a areaSelecionada
const searchQuery = ref('')
const router = useRouter()

// --- API Call ---
// Mantendo a lógica do legacy: filtro de candidatura via query param
const { data, pending, error, refresh } = await useFetch<ApiResponse>('/api/cursos/disponiveis', {
  query: computed(() => ({
    tipo_candidatura: selectedRole.value
  })),
  watch: [selectedRole]
})

// --- Computed: Mapeamento e Filtragem ---
const filteredCourses = computed<MappedCourse[]>(() => {
    const items = data.value?.items || []
    
    // 1. Mapeamento
    const mapped = items.map((curso: any, index: number) => {
        // Determinar status baseado em datas
        let status: MappedCourse['status'] = 'Open'
        const today = new Date()
        
        // Define relevant dates based on role
        const isDocente = selectedRole.value === 'docente'
        const rawStart = isDocente ? (curso.dt_ini_inscri_docente || curso.dt_ini_inscri) : curso.dt_ini_inscri
        const rawEnd = isDocente ? (curso.dt_fim_inscri_docente || curso.dt_fim_inscri) : curso.dt_fim_inscri
        
        const end = new Date(rawEnd)
        // Fix for date comparison (ensure end of day or similar if needed, but assuming strict > check)
        // Note: New date utility might help here if we imported distinct utils, but sticking to logic.
        // Actually, let's just use the raw string date for comparison if it works, or standard Date.
        if (today > end) status = 'Closed'
        
        // Normalização da Area para filtro interno
        const areaNormalized = (curso.area_curso_int || '').toLowerCase()
        
        // Try to get array, fallback to string split or empty
        let daysArray: string[] = []
        if (Array.isArray(curso.dias_semana_array)) {
            daysArray = curso.dias_semana_array
        } else if (typeof curso.dias_semana === 'string') {
             daysArray = [curso.dias_semana]
        } else if (curso.dias_semana_str) {
             daysArray = [curso.dias_semana_str]
        }

        return {
            id: curso.id_turma || curso.id,
            title: curso.nome_curso,
            description: curso.descricao_resumida || curso.nome_curso, // API pode não ter descrição
            hours: curso.qtd_horas_total || '--',
            mode: curso.turno || 'Presencial',
            status: status,
            image: 'https://spedppull.b-cdn.net/site/logosp.png', // Imagem padrão
            role: selectedRole.value,
            category: areaNormalized,
            rawDates: {
                start: rawStart,
                end: rawEnd,
                startCourse: curso.dt_ini_curso,
                endCourse: curso.dt_fim_curso
            },
            weekDays: daysArray
        }
    })

    // 2. Filtragem
    return mapped.filter(c => {
        // Filtro de Categoria (Area)
        // Lógica adaptada do legacy para suportar 'cursos_livres' e matchs parciais
        const areaCurso = c.category
        const areaFiltro = selectedCategory.value.toLowerCase()

        let categoryMatch = false
        if (areaFiltro === 'cursos_livres' && areaCurso.includes('livre')) {
            categoryMatch = true
        } else if (areaCurso === areaFiltro) {
            categoryMatch = true
        } else if (areaCurso.includes(areaFiltro)) { // Fallback parcial
             categoryMatch = true
        }

        if (!categoryMatch) return false

        // Filtro Search
        if (searchQuery.value && !c.title.toLowerCase().includes(searchQuery.value.toLowerCase())) return false
        
        return true
    })
})

const getStatusColor = (status: string) => {
    switch (status) {
        case 'Open': return 'bg-success text-white'
        case 'Closing Soon': return 'bg-warning text-white'
        case 'Waitlist': return 'bg-secondary text-white'
        default: return 'bg-primary text-white'
    }
}

const handleEnroll = (id: number) => {
    console.log('Enroll course', id)
    // Redirecionar para página de inscrição real se houver
    // navigateTo(`/inscricao/${id}`)
}
const handleInscricao = (course: MappedCourse) => {
    if (!course.id || course.id === 'undefined') {
        console.error('ID da turma não encontrado:', course)
        alert('Erro: ID da turma não disponível. Por favor, tente novamente mais tarde.')
        return
    }

    const targetPath = `/inscricao/${course.id}`
    const targetQuery = {
        tipo: course.role,
        area: course.category,
        processo: 'seletivo'
    }

    if (user.value) {
        // Logged in: go directly
        console.log('User logged in. Navigating to:', targetPath)
        navigateTo({
            path: targetPath,
            query: targetQuery
        })
    } else {
        // Not logged in: save intent and go to login
        console.log('User NOT logged in. Saving intent and redirecting to login.')
        
        redirectCookie.value = {
            path: targetPath,
            query: targetQuery,
            procedencia_form: true
        }

        navigateTo('/login')
    }
}

</script>

<template>
  <NuxtLayout name="base">
    <div class="flex flex-col gap-8 pb-10">
        
        <!-- Hero Section #0F2027 #203A43 -->
        <div class="relative w-full rounded-xl overflow-hidden bg-gradient-to-r from-[#009C82] via-[#305F7E] to-[#5C267B] text-white shadow-2xl">
            <div class="absolute inset-0 bg-[url('https://www.transparenttextures.com/patterns/cubes.png')] opacity-10"></div>
            <div class="relative z-10 px-8 py-8 md:py-24 text-center flex flex-col items-center justify-center gap-4">
                <h1 class="text-2xl md:text-5xl font-black uppercase tracking-tight drop-shadow-lg">
                    Processo Seletivo
                </h1>
                <p class="text-xs md:text-lg opacity-90 max-w-2xl font-medium leading-relaxed">
                    Navegue pelos cursos disponíveis para estudantes e docentes.
                    Selecione o tipo de candidatura e a área e clique em Inscrever-se.
                </p>
            </div>
        </div>

        <!-- Role Toggle -->
        <div class="flex justify-center -mt-4">
            <div class="bg-div-15 p-1.5 rounded-xl shadow-lg border border-secondary/10 flex items-center gap-2">
                <button 
                    @click="selectedRole = 'estudante'"
                    class="px-8 py-2.5 rounded-lg text-sm font-bold transition-all duration-300"
                    :class="selectedRole === 'estudante' ? 'bg-primary text-white shadow-md' : 'text-secondary hover:bg-div-30'"
                >
                    Estudante
                </button>
                <button 
                    @click="selectedRole = 'docente'"
                    class="px-8 py-2.5 rounded-lg text-sm font-bold transition-all duration-300"
                    :class="selectedRole === 'docente' ? 'bg-primary text-white shadow-md' : 'text-secondary hover:bg-div-30'"
                >
                    Docente
                </button>
            </div>
        </div>

        <!-- Filter Bar & Search -->
        <div class="flex flex-col md:flex-row items-center justify-between gap-4 px-2">
            <!-- Tabs -->
            <div class="flex items-center gap-6 border-b border-secondary/10 w-full md:w-auto pb-1">
                <button 
                    v-for="cat in [
                        { label: 'Extensão', value: 'extensao' },
                        { label: 'Regulares', value: 'regulares' },
                        { label: 'Cursos Livres', value: 'cursos_livres' }
                    ]" 
                    :key="cat.value"
                    @click="selectedCategory = cat.value as FilterCategory"
                    class="text-sm font-bold pb-2 relative transition-colors capitalize text-secondary hover:text-primary"
                    :class="{ 'text-primary': selectedCategory === cat.value }"
                >
                    {{ cat.label }}
                    <span v-if="selectedCategory === cat.value" class="absolute bottom-[-1px] left-0 w-full h-0.5 bg-primary rounded-full"></span>
                </button>
            </div>

            <!-- Search -->
            <div class="relative w-full md:w-80">
                <input 
                    v-model="searchQuery"
                    type="text" 
                    placeholder="Buscar cursos..."
                    class="w-full bg-div-15 border border-secondary/10 rounded-full px-5 py-2.5 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all placeholder:text-secondary/40"
                />
                <div class="absolute right-4 top-2.5 text-secondary/40">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
                </div>
            </div>
        </div>

        <!-- Course Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-[1400px] mx-auto">
            <div v-for="course in filteredCourses" :key="course.id" class="bg-background rounded-xl shadow-sm border border-secondary/10 overflow-hidden hover:shadow-xl hover:-translate-y-1 transition-all duration-300 group flex flex-col">
                
                <!-- Image Header - Clean & Narrow -->
                <div class="relative h-32 overflow-hidden flex items-center justify-center p-4 bg-[#D60956]">
                    <!-- Background Gradient Overlay -->
                    <div class="absolute inset-0 bg-gradient-to-br from-[#D60956] to-[#C40E53] z-0"></div>
                    
                    <!-- Logo (Centered & White) -->
                    <div class="relative z-10 flex flex-col items-center justify-center">
                        <img :src="course.image" :alt="course.title" class="h-16 w-auto object-contain drop-shadow-md brightness-0 invert" />
                        <!-- Se a imagem for o logo SPED, ele fica branco com brightness-0 invert. Se for foto, talvez remover essa classe? Assumindo logo SPED padrão. -->
                    </div>
                    
                    <div class="absolute top-3 right-3 text-[9px] font-black uppercase tracking-wider px-3 py-1 bg-[#95C11E] text-white rounded-md shadow-sm z-20">
                        {{ course.status === 'Open' ? 'Aberto' : 'Encerrado' }}
                    </div>
                </div>

                <!-- Content -->
                <div class="p-6 flex flex-col flex-1 gap-5">
                    
                    <!-- Title -->
                    <h3 class="text-lg font-black text-text leading-tight group-hover:text-primary transition-colors line-clamp-2 min-h-[3.5rem]">
                        {{ course.title }}
                    </h3>

                    <!-- Info Blocks -->
                    <div class="bg-div-15/50 border border-secondary/5 rounded-lg p-5 space-y-4">
                        
                        <!-- Inscricao -->
                        <div class="flex items-start gap-3">
                            <div class="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                                <svg class="w-4 h-4 text-primary" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
                            </div>
                            <div class="w-full">
                                <p class="text-[10px] uppercase font-black tracking-wider text-secondary/60 mb-0.5">Período de Inscrição</p>
                                <p class="text-sm font-bold text-text bg-background border border-secondary/5 px-2 py-1 rounded-md inline-block">
                                    {{ formatDate(course.rawDates.start, 'dd/MM') }} a {{ formatDate(course.rawDates.end, 'dd/MM/yy') }}
                                </p>
                            </div>
                        </div>

                        <!-- Período do Curso -->
                        <div class="flex items-start gap-3">
                            <div class="w-8 h-8 rounded-full bg-secondary/10 flex items-center justify-center shrink-0">
                                <svg class="w-4 h-4 text-secondary" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
                            </div>
                            <div class="w-full">
                                <p class="text-[10px] uppercase font-black tracking-wider text-secondary/60 mb-0.5">Período do Curso</p>
                                <p class="text-sm font-bold text-secondary bg-background border border-secondary/5 px-2 py-1 rounded-md inline-block">
                                    {{ course.rawDates.startCourse ? formatDate(course.rawDates.startCourse, 'dd/MM') : '--' }} 
                                    a 
                                    {{ course.rawDates.endCourse ? formatDate(course.rawDates.endCourse, 'dd/MM/yy') : '--' }}
                                </p>
                            </div>
                        </div>

                        <!-- Separator -->
                        <div class="h-px bg-secondary/10 w-full"></div>

                        <!-- Aulas (Dias) -->
                        <div class="flex items-start gap-3">
                            <div class="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                            <svg class="w-4 h-4 text-primary" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 10v6M2 10l10-5 10 5-10 5z"></path><path d="M6 12v5c3 3 9 3 12 0v-5"></path></svg>
                            </div>
                            <div class="w-full">
                                <p class="text-[10px] uppercase font-black tracking-wider text-secondary/60 mb-1">Dias de Aula</p>
                                
                                <!-- Week Days Pills -->
                                <div class="flex flex-wrap gap-1">
                                    <span 
                                        v-for="day in course.weekDays" 
                                        :key="day" 
                                        class="text-[10px] font-bold text-secondary bg-background border border-secondary/10 px-2 py-1 rounded shadow-sm uppercase"
                                    >
                                        {{ day }}
                                    </span>
                                    <span v-if="course.weekDays.length === 0" class="text-[10px] text-secondary italic">A definir</span>
                                </div>
                            </div>
                    </div>

                    </div>

                    <!-- Footer Stats -->
                    <div class="flex items-center gap-3 mt-auto">
                        <div class="flex-1 flex items-center justify-center gap-2 bg-div-15 rounded-xl py-3 text-xs font-bold text-secondary border border-secondary/5">
                            <svg class="w-4 h-4 text-primary" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
                            {{ course.hours }} Horas
                        </div>
                        <div class="flex-1 flex items-center justify-center gap-2 bg-div-15 rounded-xl py-3 text-xs font-bold text-secondary border border-secondary/5">
                            <svg class="w-4 h-4 text-primary" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s-8-4.5-8-11.8A8 8 0 0 1 12 2a8 8 0 0 1 8 8.2c0 7.3-8 11.8-8 11.8z"></path><circle cx="12" cy="10" r="3"></circle></svg>
                            {{ course.mode }}
                        </div>
                    </div>

                    <!-- CTA Button -->
                    <button 
                    @click="handleInscricao(course)"
                    class="w-full bg-primary text-white font-black py-4 rounded-xl text-sm uppercase tracking-widest shadow-lg shadow-primary/20 hover:bg-[#b81151] hover:shadow-primary/30 hover:-translate-y-0.5 transition-all active:scale-[0.98] flex items-center justify-center gap-2 group-hover:animate-pulse"
                    >
                        Inscrever-se
                        <svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"></line><polyline points="12 5 19 12 12 19"></polyline></svg>
                    </button>

                </div>
            </div>
        </div>

    </div>

    <template #sidebar>
        <!-- Widget: Instructions -->
        <div>
            <h4 class="text-[9px] font-black text-primary uppercase tracking-[0.2em] mb-4 flex items-center gap-2">
                <span class="w-1.5 h-1.5 rounded-full bg-primary"></span>
                Instruções
            </h4>
            <p class="text-[11px] text-secondary font-medium leading-relaxed mb-4">
                Para se inscrever, sigas os passos abaixo
            </p>
            <div class="space-y-2">
                <div class="flex items-center gap-3 text-[10px] font-bold text-text/80 bg-background px-3 py-2 rounded-md border border-secondary/5">
                    <span class="text-primary font-black">1.</span> Escolha o tipo de candidatura
                </div>
                <div class="flex items-center gap-3 text-[10px] font-bold text-text/80 bg-background px-3 py-2 rounded-md border border-secondary/5">
                    <span class="text-primary font-black">2.</span> Escolha a área de interesse
                </div>
                <div class="flex items-center gap-3 text-[10px] font-bold text-text/80 bg-background px-3 py-2 rounded-md border border-secondary/5">
                    <span class="text-primary font-black">3.</span> Clique em "Inscrever-se"
                </div>
                <div class="flex items-center gap-3 text-[10px] font-bold text-text/80 bg-background px-3 py-2 rounded-md border border-secondary/5">
                    <span class="text-primary font-black">4.</span> Preencha os dados
                </div>
                <div class="flex items-center gap-3 text-[10px] font-bold text-text/80 bg-background px-3 py-2 rounded-md border border-secondary/5">
                    <span class="text-primary font-black">5.</span> Clique em "Enviar"
                </div>
                <div class="flex items-center gap-3 text-[10px] font-bold text-text/80 bg-background px-3 py-2 rounded-md border border-secondary/5">
                    <span class="text-primary font-black">6.</span> Acompanhe seu processo em /meus_processos
                </div>
            </div>
        </div>
        
        <div class="w-full h-[1px] bg-secondary/10 my-6"></div>

        <!-- Widget: Links -->
        <div>
            <h4 class="text-[9px] font-black text-secondary uppercase tracking-[0.2em] mb-3">Links Úteis</h4>
            <nav class="flex flex-col gap-1.5">
                <a href="https://spescoladedanca.org.br/" target="_blank" rel="noopener noreferrer" class="text-[11px] font-bold text-secondary hover:text-primary transition-colors flex items-center gap-1 group">
                    <span class="group-hover:translate-x-1 transition-transform duration-200">→</span> Site São Paulo Escola de Dança
                </a>
            </nav>
        </div>
    </template>
  </NuxtLayout>
</template>
