<script setup lang="ts">
import { useToast } from '../../composables/useToast';

const props = defineProps<{
    isOpen: boolean;
    area: string;
    anoSemestre: string;
}>();

const emit = defineEmits(['close']);
// const client = useSupabaseClient(); // Removed as using BFF
const { showToast } = useToast();

const isLoading = ref(false);
const activeTab = ref<'config' | 'preview'>('config');
const dataInicio = ref('');

// Global Config State
const config = ref({
    tituloCentral_1: 'Processo Seletivo',
    tituloCentral_2: 'Cursos Regulares | São Paulo Escola de Dança',
    tituloCentral_3: 'Habilitados(as/es) para a ETAPA I e II',
    dataEtapas: 'dia 01 a 03/12/2025',
    logoUrl: 'https://spedppull.b-cdn.net/site/sped_logo_total%20(1).png'
});

// Data State
const turmas = ref<any[]>([]);

// Computed for Process Name (e.g., 26Is -> 2026.1)
const nomeProcesso = computed(() => {
    if (!props.anoSemestre) return '';
    // Basic formatting logic: 26Is -> 2026.1, 26IIs -> 2026.2
    let year = props.anoSemestre.substring(0, 2);
    let semester = props.anoSemestre.includes('IIs') ? '2' : '1';
    return `20${year}.${semester}`;
});

// Fetch Data
const fetchData = async () => {
    if (!props.isOpen) return;

    isLoading.value = true;
    try {
        const data = await $fetch('/api/selecao/lista-homologados', {
            params: {
              area: props.area,
              anoSemestre: props.anoSemestre,
              dataInicio: dataInicio.value || undefined
            }
        });
        
        // Initialize local config for each turma if not present
        turmas.value = ((data as any[]) || []).map((t: any) => ({
            ...t,
            // Local editable overrides (default to what comes from DB or empty)
            custom_data_prova: t.data_prova || '',
            custom_hora_redacao: t.hora_redacao || '',
            custom_hora_pratica: t.hora_pratica || '',
            custom_cabecalho: t.cabecalho || '',
            isExpanded: false,
            isPreviewExpanded: false,
            isSaving: false,
            lastSaved: null
        })).sort((a: any, b: any) => a.nome_turma.localeCompare(b.nome_turma));

    } catch (e) {
        console.error('Error fetching list:', e);
        showToast('Erro ao buscar lista de homologados.', { type: 'error' });
    } finally {
        isLoading.value = false;
    }
};

const saveParams = async (turma: any) => {
    turma.isSaving = true;
    try {
        await $fetch('/api/selecao/parametros-homologacao', {
            method: 'POST',
            body: {
                id_turma: turma.id_turma,
                data_prova: turma.custom_data_prova,
                hora_redacao: turma.custom_hora_redacao,
                hora_prova_pratica: turma.custom_hora_pratica,
                texto_cabecalho_curso: turma.custom_cabecalho
            }
        });
        
        turma.lastSaved = new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
    } catch (e) {
        console.error('Error saving params:', e);
        showToast('Erro ao salvar configurações da turma.', { type: 'error' });
    } finally {
        turma.isSaving = false;
    }
};

watch(() => props.isOpen, (val) => {
    if (val) {
        fetchData();
        activeTab.value = 'config';
    }
});

// Print Logic
const printPDF = (items: any[] = []) => {
    // If no items passed, use all turmas
    const targetItems = items.length > 0 ? items : turmas.value;

    // Generate HTML based on current state
    const htmlContent = generateFullHTML(targetItems);
    
    // Create iframe
    const iframe = document.createElement('iframe');
    Object.assign(iframe.style, {
        position: 'fixed',
        right: '0',
        bottom: '0',
        width: '0',
        height: '0',
        border: '0'
    });
    document.body.appendChild(iframe);

    const doc = iframe.contentDocument || (iframe.contentWindow && iframe.contentWindow.document);
    if (!doc) return;

    doc.open();
    doc.write(htmlContent);
    doc.close();

    // Image loading handler
    const waitForImages = () => {
        const images = doc.images;
        if (!images.length) {
            printNow(iframe);
            return;
        }

        let loadedCount = 0;
        const checkComplete = () => {
            loadedCount++;
            if (loadedCount === images.length) {
                printNow(iframe);
            }
        };

        for (let i = 0; i < images.length; i++) {
            const img = images[i];
            if (!img) continue; // Safety check
            
            if (img.complete) {
                checkComplete();
            } else {
                img.addEventListener('load', checkComplete);
                img.addEventListener('error', checkComplete);
            }
        }
    };

    iframe.onload = () => waitForImages();
    setTimeout(() => waitForImages(), 500); // Fallback
};

const printClass = (turma: any) => {
    printPDF([turma]);
};

const printNow = (iframe: HTMLIFrameElement) => {
    // Prevent double printing
    if ((iframe as any)._hasPrinted) return;
    (iframe as any)._hasPrinted = true;

    if (!iframe.contentWindow) return;
    
    setTimeout(() => {
        iframe.contentWindow?.focus();
        iframe.contentWindow?.print();
        setTimeout(() => {
             if (document.body.contains(iframe)) {
                 document.body.removeChild(iframe);
             }
        }, 1000);
    }, 300);
};

// --- Generator Functions ---

const generateStyles = () => `
       * { box-sizing: border-box; font-family: 'Poppins', sans-serif; color: #222; font-size: 13px; }
       .pagina { padding: 10mm 10mm; width: 100%; margin: 0; }
       .pagina + .pagina { page-break-before: always; }
       .cabecalho-interno { text-align: center; margin-top: 0; margin-bottom: 22px; font-size: 13px; line-height: 1.45; }
       .logo-cabecalho { width: 120px; margin-bottom: 10px; }
       .linhas-centrais div { margin: 2px 0; font-weight: 700; }
       .texto-etapas { margin-top: 12px; white-space: normal; text-align: center; font-size: 13px; }
       .bloco-cabecalho-turma { margin-bottom: 20px; }
       .info-turma p { margin: 3px 0; font-size: 13px; }
       .titulo-turma { font-size: 15px; font-weight: 700; }
       .texto-prova { margin-top: 12px; margin-bottom: 22px; line-height: 1.5; font-size: 13px; }
       .titulo-lista { margin-top: 16px; margin-bottom: 8px; font-weight: 700; font-size: 13px; }
       .aluno-item { padding: 6px 0; border-bottom: 1px solid #eee; font-size: 13px; }
       .aluno-item:last-of-type { border-bottom: none; }
       
       /* Print Settings */
       @page { size: A4; margin: 10mm; }
       html, body { width: 210mm; min-height: 297mm; background: white; margin: 0; padding: 0; }
       img { max-width: 100%; height: auto; }
`;

const generateBody = (items: any[]) => {
    // Pre-process turmas with custom values
    const turmasProcessed = items.map(t => ({
        ...t,
        data_prova: t.custom_data_prova,
        hora_redacao: t.custom_hora_redacao,
        hora_pratica: t.custom_hora_pratica,
        cabecalho: t.custom_cabecalho
    })).filter(t => (t.alunos || []).length > 0);

    const fullTitle1 = `${config.value.tituloCentral_1} - ${nomeProcesso.value}`;
    
    // Helper formatting
    const fmt = (v: any) => v ? v : "";

    const textoEndereco = `
    presencialmente, no seguinte endereço: R. Mauá, 51 - 3º andar - Luz, São Paulo - SP - Complexo Júlio Prestes. 
    Atente-se para o dia e o horário da sua prova descritos abaixo. Chegue com 30 minutos de antecedência para registro de entrada na portaria. 
    Qualquer dúvida, escreva para secretaria@spescoladedanca.org.br ou pelo telefone: (11) 91593-2046.
    `;

    // Blocks
    const blocoCabecalhoInstitucional = () => `
        <div class="cabecalho-interno">
          <img src="${config.value.logoUrl}" class="logo-cabecalho" />
          <div class="linhas-centrais">
            <div class="linha-1"><strong>${fullTitle1}</strong></div>
            <div class="linha-2"><strong>${config.value.tituloCentral_2}</strong></div>
            <div class="linha-3"><strong>${config.value.tituloCentral_3}</strong></div>
          </div>
          <div class="texto-etapas">
            As Etapas I e II acontecerão no <strong>${config.value.dataEtapas}</strong> ${textoEndereco}
          </div>
        </div>
    `;

    const blocoInfoTurma = (t: any) => `
        <div class="bloco-cabecalho-turma">
          <div class="info-turma">
            <p class="titulo-turma"><strong>${t.nome_turma}</strong></p>
            <p><strong>Turno:</strong> ${fmt(t.turno)}</p>
            <p><strong>Data da Prova:</strong> ${fmt(t.data_prova)}</p>
            <p><strong>Hora da Redação:</strong> ${fmt(t.hora_redacao)}</p>
            <p><strong>Hora da Prova Prática:</strong> ${fmt(t.hora_pratica)}</p>
          </div>
          <div class="texto-prova">
            ${(t.cabecalho || "").replace(/\n/g, '<br>')}
          </div>
        </div>
    `;

    const blocoListaAlunos = (t: any) => `
        <div class="titulo-lista">Lista de Alunos</div>
        ${(t.alunos || []).map((a: any, i: number) => `
          <div class="aluno-item">
           ${i + 1} - ${a.nome}
          </div>`
        ).join("")}
    `;

    // Build Body
    let primeira = true;
    return turmasProcessed.map((t) => {
        const header = primeira ? blocoCabecalhoInstitucional() : "";
        primeira = false;
        return `
            <div class="pagina">
                ${header}
                ${blocoInfoTurma(t)}
                ${blocoListaAlunos(t)}
            </div>
        `;
    }).join("");
};

const generateFullHTML = (items: any[]) => {
    return `
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <title>Processo Seletivo</title>
        <style>
          ${generateStyles()}
        </style>
      </head>
      <body>
        ${generateBody(items)}
      </body>
    </html>
    `;
};

</script>

<template>
  <div v-if="isOpen" class="relative z-50">
    <!-- Backdrop -->
    <div class="fixed inset-0 bg-black/80 backdrop-blur-sm transition-opacity" @click="$emit('close')"></div>

    <!-- Modal -->
    <div class="fixed inset-0 z-10 overflow-y-auto">
      <div class="flex min-h-full items-center justify-center p-0 md:p-4 text-center">
        <div class="relative w-full max-w-4xl transform rounded-none md:rounded-xl bg-[#16161E] border border-white/10 text-left shadow-xl transition-all flex flex-col max-h-[90vh]">
            
            <div class="flex items-center justify-between p-6 border-b border-white/10">
                <div class="flex flex-col gap-1">
                    <h3 class="text-xl font-bold text-white">
                        Gerar Lista de Homologados
                        <span class="block text-sm text-secondary font-normal mt-1 capitalize">{{ area }} | {{ anoSemestre }}</span>
                    </h3>
                </div>
                <div class="flex items-center gap-3">
                    <!-- Date Filter -->
                    <div class="flex items-center gap-2 bg-[#0f0f15] border border-white/10 rounded-lg p-1.5 pl-3">
                         <span class="text-xs font-bold text-secondary uppercase tracking-wider">A partir de:</span>
                         <input 
                            v-model="dataInicio" 
                            type="date" 
                            class="bg-transparent text-white text-xs font-bold outline-none border-none p-0 w-28 placeholder-secondary/50"
                         />
                         <button 
                            v-if="dataInicio"
                            @click="dataInicio = ''"
                            class="w-5 h-5 flex items-center justify-center text-secondary hover:text-red-400 transition-colors"
                            title="Limpar filtro de data"
                         >
                            <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                         </button>
                         <button 
                            @click="fetchData"
                            class="bg-primary/20 hover:bg-primary/30 text-primary text-xs font-bold px-3 py-1.5 rounded transition-colors"
                         >
                            Filtrar
                         </button>
                    </div>

                    <button @click="$emit('close')" class="text-secondary hover:text-white transition-colors ml-4">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                    </button>
                </div>
            </div>

            <!-- Tabs -->
            <div class="flex border-b border-white/10 px-6">
                <button 
                    @click="activeTab = 'config'"
                    class="px-4 py-3 text-sm font-bold border-b-2 transition-colors"
                    :class="activeTab === 'config' ? 'border-primary text-primary' : 'border-transparent text-secondary hover:text-white'"
                >
                    Configurar Relatório
                </button>
                <button 
                    @click="activeTab = 'preview'"
                    class="px-4 py-3 text-sm font-bold border-b-2 transition-colors"
                    :class="activeTab === 'preview' ? 'border-primary text-primary' : 'border-transparent text-secondary hover:text-white'"
                >
                    Visualizar Lista (Preview)
                </button>
            </div>

            <!-- Content Area -->
            <div class="flex-1 overflow-y-auto p-6 custom-scrollbar">
                
                <div v-if="isLoading" class="flex justify-center py-10">
                    <div class="animate-spin rounded-full h-10 w-10 border-t-2 border-primary"></div>
                </div>

                <div v-else-if="turmas.length === 0" class="flex flex-col items-center justify-center py-10 opacity-50">
                     <p>Nenhuma turma encontrada.</p>
                </div>

                <!-- CONFIG TAB -->
                <div v-else-if="activeTab === 'config'" class="space-y-8">
                    
                    <!-- Global Settings -->
                    <div class="bg-white/5 rounded-lg p-5 border border-white/10">
                        <h4 class="text-sm font-bold text-white mb-4 uppercase tracking-wider">Cabeçalho Geral</h4>
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div class="md:col-span-2">
                                <label class="block text-xs font-bold text-secondary mb-1">Título Central 1 (Prefixo)</label>
                                <input v-model="config.tituloCentral_1" class="w-full bg-[#0f0f15] border border-white/10 rounded px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" />
                            </div>
                            <div class="md:col-span-2">
                                <label class="block text-xs font-bold text-secondary mb-1">Título Central 2 (Instituição)</label>
                                <input v-model="config.tituloCentral_2" class="w-full bg-[#0f0f15] border border-white/10 rounded px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" />
                            </div>
                             <div class="md:col-span-2">
                                <label class="block text-xs font-bold text-secondary mb-1">Título Central 3 (Subtítulo)</label>
                                <input v-model="config.tituloCentral_3" class="w-full bg-[#0f0f15] border border-white/10 rounded px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" />
                            </div>
                            <div class="md:col-span-2">
                                <label class="block text-xs font-bold text-secondary mb-1">Texto da Data das Etapas</label>
                                <input v-model="config.dataEtapas" type="text" class="w-full bg-[#0f0f15] border border-white/10 rounded px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" />
                                <p class="text-[10px] text-secondary mt-1">Ex: dia 01 a 03/12/2025</p>
                            </div>
                        </div>
                    </div>

                    <!-- Courses Settings -->
                    <div>
                         <h4 class="text-sm font-bold text-white mb-4 uppercase tracking-wider">Configuração por Turma ({{ turmas.length }})</h4>
                         <div class="space-y-3">
                             <div v-for="turma in turmas" :key="turma.id_turma" class="bg-white/5 border border-white/10 rounded-lg overflow-hidden">
                                 <button @click="turma.isExpanded = !turma.isExpanded" class="w-full flex items-center justify-between p-4 hover:bg-white/5 transition-colors text-left">
                                     <div class="flex flex-col">
                                         <p class="font-bold text-white text-sm">{{ turma.nome_turma }}</p>
                                         <p class="text-xs text-secondary mt-0.5">{{ turma.turno }}</p>
                                         <div v-if="(turma.alunos || []).length === 0" class="flex items-center gap-1 mt-1 text-xs text-yellow-500 font-bold">
                                             <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path></svg>
                                             Sem alunos nesta turma
                                         </div>
                                     </div>
                                     <svg class="w-5 h-5 text-secondary transition-transform" :class="{'rotate-180': turma.isExpanded}" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
                                 </button>
                                 
                                 <div v-show="turma.isExpanded" class="p-4 pt-0 border-t border-white/10 mt-2 space-y-4">
                                     <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mt-4">
                                         <div>
                                             <label class="block text-xs font-bold text-secondary mb-1">Data da Prova</label>
                                             <div class="flex gap-2">
                                                 <input 
                                                    v-model="turma.custom_data_prova" 
                                                    @blur="saveParams(turma)"
                                                    class="w-full bg-[#0f0f15] border border-white/10 rounded px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" 
                                                    placeholder="Ex: 05/12/2025" 
                                                 />
                                                 <button @click="saveParams(turma)" class="text-primary hover:text-primary-600 transition-colors p-1" title="Salvar">
                                                     <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 3H5a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2V7l-4-4zm-5 16a2 2 0 110-4 2 2 0 010 4zm3-10H9V5h6v4z"></path></svg>
                                                 </button>
                                             </div>
                                             <div class="mt-1 h-4">
                                                 <span v-if="turma.isSaving" class="text-xs text-yellow-500 animate-pulse">Aguarde...</span>
                                                 <span v-else-if="turma.lastSaved" class="text-xs text-green-500">Salvo às {{ turma.lastSaved }}</span>
                                             </div>
                                         </div>
                                         <div>
                                             <label class="block text-xs font-bold text-secondary mb-1">Hora Redação</label>
                                             <div class="flex gap-2">
                                                 <input 
                                                    v-model="turma.custom_hora_redacao" 
                                                    @blur="saveParams(turma)"
                                                    class="w-full bg-[#0f0f15] border border-white/10 rounded px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" 
                                                    placeholder="Ex: 09h" 
                                                 />
                                                 <button @click="saveParams(turma)" class="text-primary hover:text-primary-600 transition-colors p-1" title="Salvar">
                                                     <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 3H5a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2V7l-4-4zm-5 16a2 2 0 110-4 2 2 0 010 4zm3-10H9V5h6v4z"></path></svg>
                                                 </button>
                                             </div>
                                             <div class="mt-1 h-4">
                                                 <span v-if="turma.isSaving" class="text-xs text-yellow-500 animate-pulse">Aguarde...</span>
                                                 <span v-else-if="turma.lastSaved" class="text-xs text-green-500">Salvo às {{ turma.lastSaved }}</span>
                                             </div>
                                         </div>
                                         <div>
                                             <label class="block text-xs font-bold text-secondary mb-1">Hora Prática</label>
                                             <div class="flex gap-2">
                                                 <input 
                                                    v-model="turma.custom_hora_pratica" 
                                                    @blur="saveParams(turma)"
                                                    class="w-full bg-[#0f0f15] border border-white/10 rounded px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" 
                                                    placeholder="Ex: 10h30" 
                                                 />
                                                 <button @click="saveParams(turma)" class="text-primary hover:text-primary-600 transition-colors p-1" title="Salvar">
                                                     <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 3H5a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2V7l-4-4zm-5 16a2 2 0 110-4 2 2 0 010 4zm3-10H9V5h6v4z"></path></svg>
                                                 </button>
                                             </div>
                                             <div class="mt-1 h-4">
                                                 <span v-if="turma.isSaving" class="text-xs text-yellow-500 animate-pulse">Aguarde...</span>
                                                 <span v-else-if="turma.lastSaved" class="text-xs text-green-500">Salvo às {{ turma.lastSaved }}</span>
                                             </div>
                                         </div>
                                         <div class="md:col-span-3">
                                             <label class="block text-xs font-bold text-secondary mb-1">Texto/Cabeçalho da Prova</label>
                                             <div class="flex gap-2">
                                                 <textarea 
                                                    v-model="turma.custom_cabecalho" 
                                                    @blur="saveParams(turma)"
                                                    rows="4" 
                                                    class="w-full bg-[#0f0f15] border border-white/10 rounded px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" 
                                                    placeholder="Instruções específicas para esta turma..."
                                                 ></textarea>
                                                 <button @click="saveParams(turma)" class="text-primary hover:text-primary-600 transition-colors p-1" title="Salvar">
                                                     <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 3H5a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2V7l-4-4zm-5 16a2 2 0 110-4 2 2 0 010 4zm3-10H9V5h6v4z"></path></svg>
                                                 </button>
                                             </div>
                                             <div class="mt-1 h-4">
                                                 <span v-if="turma.isSaving" class="text-xs text-yellow-500 animate-pulse">Aguarde...</span>
                                                 <span v-else-if="turma.lastSaved" class="text-xs text-green-500">Salvo às {{ turma.lastSaved }}</span>
                                             </div>
                                         </div>
                                     </div>
                                 </div>
                             </div>
                         </div>
                    </div>

                </div>

                <!-- PREVIEW TAB -->
                <div v-else-if="activeTab === 'preview'" class="space-y-6">
                    <div v-for="turma in turmas" :key="turma.id_turma" v-show="(turma.alunos || []).length > 0" class="bg-white/5 border border-white/10 rounded-lg overflow-hidden">
                        <div class="w-full flex justify-between items-center p-5 hover:bg-white/5 transition-colors text-left group">
                             <button 
                                @click="turma.isPreviewExpanded = !turma.isPreviewExpanded" 
                                class="flex-1 flex justify-between items-center pr-4"
                             >
                                 <div class="flex flex-col gap-1 text-left">
                                     <h4 class="font-bold text-white">{{ turma.nome_turma }}</h4>
                                     <span class="text-xs text-secondary w-fit bg-white/5 px-2 py-0.5 rounded">{{ turma.turno }}</span>
                                 </div>
                                 <div class="flex items-center gap-4">
                                     <span class="text-xs font-bold text-white bg-primary/20 text-primary px-2 py-1 rounded">
                                         {{ (turma.alunos || []).length }} alunos
                                     </span>
                                     <svg 
                                        class="w-5 h-5 text-secondary transition-transform duration-200"
                                        :class="{'rotate-180': turma.isPreviewExpanded}" 
                                        fill="none" 
                                        stroke="currentColor" 
                                        viewBox="0 0 24 24"
                                     >
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
                                     </svg>
                                 </div>
                             </button>
                             
                             <!-- Per-class Print Button -->
                             <button
                                @click.stop="printClass(turma)"
                                class="p-2 text-primary hover:text-primary hover:bg-white/10 rounded-lg transition-colors ml-2 border-l border-white/10 pl-4"
                                title="Imprimir somente esta turma"
                             >
                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"></path></svg>
                             </button>
                        </div>

                        <div v-show="turma.isPreviewExpanded" class="p-5 pt-0 border-t border-white/10">
                            <div class="space-y-1 mt-4">
                                <div v-for="(aluno, idx) in turma.alunos" :key="idx" class="flex gap-3 text-sm text-secondary-300 py-1 border-b border-white/5 last:border-0">
                                    <span class="w-8 text-right font-mono opacity-50">{{ Number(idx) + 1 }}.</span>
                                    <span class="text-white">{{ aluno.nome }}</span>
                                </div>
                                <div v-if="!turma.alunos || turma.alunos.length === 0" class="text-xs text-secondary/50 italic py-2">
                                    Nenhum aluno nesta lista.
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

            </div>

            <!-- Footer -->
            <div class="p-4 border-t border-white/10 flex justify-end gap-3 bg-[#16161E]">
                <button 
                    @click="$emit('close')"
                    class="px-6 py-2.5 bg-white/5 hover:bg-white/10 text-secondary hover:text-white font-bold rounded-lg transition-colors"
                >
                    Cancelar
                </button>

                <button 
                    v-if="activeTab === 'preview'"
                    @click="printPDF()"
                    class="px-6 py-2.5 bg-primary hover:bg-primary-600 text-white font-bold rounded-lg transition-colors flex items-center gap-2"
                >
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"></path></svg>
                    Imprimir Relatório
                </button>
            </div>

        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: rgba(255, 255, 255, 0.05); }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.1); border-radius: 10px; }
</style>
