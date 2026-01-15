<script setup lang="ts">
import { useToast } from '../../composables/useToast';

const props = defineProps<{
    isOpen: boolean;
    area: string;
    anoSemestre: string;
}>();

const emit = defineEmits(['close']);
const { showToast } = useToast();

const activeTab = ref<'config' | 'preview'>('config');
const isLoading = ref(false);
const turmas = ref<any[]>([]);

// Config Fields with Defaults
const config = reactive({
    semestreModulo: '1º semestre de 2026, correspondentes ao Módulo Fogo',
    periodoMatricula: '06 a 08 de dezembro até às 12h00 (horário de Brasília).',
    tipoProcesso: 'seletivo',
    tipoCandidatura: 'estudante'
});

// Fetch Data
const fetchData = async () => {
    isLoading.value = true;
    try {
        const data = await $fetch('/api/selecao/lista-selecionados', {
            params: {
                area: props.area,
                anoSemestre: props.anoSemestre,
                tipoProcesso: config.tipoProcesso,
                tipoCandidatura: config.tipoCandidatura
            }
        });
        
        // Sort students alphabetically
        const turmasData = (data as any[]) || [];
        turmasData.forEach(t => {
             t.alunos.sort((a: any, b: any) => a.nome.localeCompare(b.nome));
             t.isPreviewExpanded = false; // Default collapsed
        });
        
        // Sort classes alphabetically
        turmasData.sort((a, b) => a.nome_turma.localeCompare(b.nome_turma));

        turmas.value = turmasData;
    } catch (error) {
        console.error(error);
        showToast('Erro ao carregar lista de selecionados.', { type: 'error' });
    } finally {
        isLoading.value = false;
    }
};

// Initial Fetch
watch(() => props.isOpen, (newVal) => {
    if (newVal) {
        activeTab.value = 'config';
        fetchData();
    }
});

// --- PRINT LOGIC ---

const printPDF = (specificTurmas?: any[]) => {
    const itemsToPrint = specificTurmas || turmas.value;
    
    // Create hidden iframe
    const iframe = document.createElement('iframe');
    iframe.style.position = 'fixed';
    iframe.style.right = '0';
    iframe.style.bottom = '0';
    iframe.style.width = '0';
    iframe.style.height = '0';
    iframe.style.border = '0';
    document.body.appendChild(iframe);

    // Write content
    const doc = iframe.contentWindow?.document;
    if (!doc) return;

    const htmlContent = generateFullHTML(itemsToPrint);
    
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
            if (!img) continue;
            
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

const printNow = (iframe: HTMLIFrameElement) => {
    // Prevent double printing if called multiple times
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

const printClass = (turma: any) => {
    printPDF([turma]);
};


// --- HTML GENERATORS ---

// --- HTML GENERATORS ---

const generateStyles = () => `
  * {
    box-sizing: border-box;
    font-family: 'Poppins', sans-serif;
    color: #222;
    font-size: 13px;
  }

 .pagina {
  padding: 3mm 10mm;
  width: 100%;
  margin: 0;
  page-break-inside: avoid !important;
}

/* Espaço ENTRE turmas */
 .pagina + .pagina {
  margin-top: 0;  /* ⬅ Mude esse número para mais ou menos espaço */
  page-break-before: avoid !important;
}


  /* CABEÇALHO FIXO */
  .cabecalho-interno {
    text-align: center;
    margin-top: 0;
    margin-bottom: 22px;
    font-size: 13px;
    line-height: 1.45;
  }

  .logo-cabecalho {
    width: 120px;
    margin-bottom: 10px;
  }

  .linhas-centrais div {
    margin: 2px 0;
    font-weight: 700;
  }

  .texto-etapas {
    margin-top: 12px;
    white-space: normal;
    text-align: left;
    font-size: 13px;
  }

  /* BLOCO DA TURMA */
  .bloco-cabecalho-turma {
    margin-bottom: 20px;
  }

  .info-turma p {
    margin: 3px 0;
    font-size: 13px;
  }

  .titulo-turma {
    font-size: 15px;
    font-weight: 700;
  }

  /* LISTA */
  .titulo-lista {
    margin-top: 6px;
    margin-bottom: 6px;
    font-weight: 700;
    font-size: 12px;
  }

  .aluno-item {
    padding: 6px 0;
    border-bottom: 1px solid #eee;
    font-size: 13px;
  }

  .aluno-item:last-of-type {
    border-bottom: none;
  }
`;

const generateBody = (items: any[]) => {
    const logoUrl = "https://spedppull.b-cdn.net/site/sped_logo_total%20(1).png";
    
    // Variables
    const nomeProcesso = props.anoSemestre || "";
    const tituloCentral_1 = `Processo Seletivo - ${nomeProcesso}`;
    const tituloCentral_2 = "Cursos Regulares | São Paulo Escola de Dança";
    const tituloCentral_3 = "Lista de Aprovados(as)";
    
    // Dynamic Configs
    const semestre = config.semestreModulo || "";
    const datamatricula = config.periodoMatricula || "";

    // Helper functions
    const blocoCabecalhoInstitucional = () => `
        <div class="cabecalho-interno">
            <img src="${logoUrl}" class="logo-cabecalho" />

            <div class="linhas-centrais">
                <div class="linha-1"><strong>${tituloCentral_1}</strong></div>
                <div class="linha-2"><strong>${tituloCentral_2}</strong></div>
                <div class="linha-3"><strong>${tituloCentral_3}</strong></div>
            </div>

            <div class="texto-etapas">
                A Associação Pró-Dança - APD, Organização Social de Cultura, inscrita no CNPJ de nº. 11.035.916/0003-65 (filial), com filial na Rua Mauá, nº. 51, 3º andar, Centro, São Paulo/SP, CEP 01028-000, gestora da São Paulo Escola de Dança – Centro de Formação em Artes Coreográficas, nos termos do Contrato de Gestão nº. 05/2021 celebrado com o Estado de São Paulo por intermédio de sua Secretaria de Cultura, Economia e Indústria Criativas, torna pública a lista de aprovados(as) no processo seletivo dos Cursos Regulares do <strong>${semestre}</strong> <br> <strong> O link da matrícula será enviado para o e-mail cadastrado na inscrição. Fique atento à sua caixa de SPAM. </strong> <br> Período de matrícula on-line: <strong>${datamatricula}</strong>. <br> O candidato aprovado que não efetivar a matrícula no prazo estipulado perderá automaticamente o direito à vaga. <br> Qualquer dúvida, escreva para o e-mail <strong> secretaria@spescoladedanca.org.br </strong> ou entre em contato pelo telefone <strong> (11) 3367-5900 </strong> ou WhatsApp <strong> (11) 91593-2046 </strong>.
            </div>
        </div>
    `;

    const blocoInfoTurma = (t: any) => `
        <div class="bloco-cabecalho-turma">
            <div class="info-turma">
                <p class="titulo-turma"><strong>${t.nome_turma}</strong></p> - <strong>${t.turno}</strong></p>
            </div>
        </div>
    `;

    const blocoListaAlunos = (t: any) => `
        <div class="titulo-lista">Candidatos Aprovados</div>
        ${(t.alunos || [])
            .map((a: any, i: number) => `
                <div class="aluno-item">
                    ${i + 1} - ${a.nome}
                </div>
            `).join("")}
    `;

    // Render loop
    let primeira = true;
    
    // Filter out empty classes if needed, or keep them as per requirement. 
    // Assuming we print check the ones passed in 'items'.
    return items.map((t) => {
        // Skip empty classes from printing if they have no students? 
        // Logic in previous version skipped empty. Let's keep skipping empty if no students.
        if (!t.alunos || t.alunos.length === 0) return '';

        const header = primeira ? blocoCabecalhoInstitucional() : "";
        primeira = false; // Layout requirement: Header only on first page/start.

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
          <title>Lista de Selecionados</title>
          <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
          <style>${generateStyles()}</style>
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
            <div class="flex min-h-full items-center justify-center p-4 text-center">
                <div class="relative w-full max-w-4xl transform overflow-hidden rounded-2xl bg-[#1A1B26] text-left align-middle shadow-xl transition-all border border-white/10 flex flex-col max-h-[90vh]">
                    
                    <!-- Header -->
                    <div class="p-6 border-b border-white/10 flex justify-between items-center bg-[#16161E]">
                        <div>
                            <h3 class="text-lg font-bold text-white">
                                Gerar Lista de Selecionados
                            </h3>
                            <p class="text-xs text-secondary mt-1">
                                {{ props.area }} | {{ props.anoSemestre }}
                            </p>
                        </div>
                        
                        <button @click="$emit('close')" class="text-secondary hover:text-white transition-colors">
                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                        </button>
                    </div>

                    <!-- Tabs -->
                    <div class="flex border-b border-white/10 bg-[#16161E]">
                        <button 
                            @click="activeTab = 'config'" 
                            class="px-6 py-3 text-sm font-medium border-b-2 transition-colors"
                            :class="activeTab === 'config' ? 'border-primary text-white' : 'border-transparent text-secondary hover:text-white'"
                        >
                            Configurar Texto
                        </button>
                        <button 
                            @click="activeTab = 'preview'" 
                            class="px-6 py-3 text-sm font-medium border-b-2 transition-colors"
                            :class="activeTab === 'preview' ? 'border-primary text-white' : 'border-transparent text-secondary hover:text-white'"
                        >
                            Visualizar e Imprimir
                        </button>
                    </div>

                    <!-- Content -->
                    <div class="p-6 bg-[#1A1B26] overflow-y-auto custom-scrollbar flex-1">
                        
                        <div v-if="isLoading" class="flex justify-center items-center py-20">
                            <div class="animate-spin rounded-full h-10 w-10 border-t-2 border-primary"></div>
                        </div>

                        <div v-else>
                            <!-- CONFIG TAB -->
                            <div v-show="activeTab === 'config'" class="space-y-6">
                                
                                <div class="bg-white/5 rounded-lg p-5 border border-white/5">
                                    <label class="block text-xs font-bold text-secondary uppercase mb-2">Semestre e Módulo</label>
                                    <p class="text-[10px] text-secondary/50 mb-2">Complementa a frase: "...dos Cursos Regulares do [TEXTO]"</p>
                                    <input 
                                        v-model="config.semestreModulo" 
                                        type="text" 
                                        class="w-full bg-[#16161E] border border-white/10 rounded-lg px-4 py-2.5 text-white text-sm focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-all"
                                    />
                                </div>

                                <div class="bg-white/5 rounded-lg p-5 border border-white/5">
                                    <label class="block text-xs font-bold text-secondary uppercase mb-2">Período de Matrícula</label>
                                    <p class="text-[10px] text-secondary/50 mb-2">Complementa a frase: "Período de matrícula on-line: [TEXTO]"</p>
                                    <input 
                                        v-model="config.periodoMatricula" 
                                        type="text" 
                                        class="w-full bg-[#16161E] border border-white/10 rounded-lg px-4 py-2.5 text-white text-sm focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-all"
                                    />
                                </div>

                                <div class="flex p-4 mb-4 text-sm text-yellow-500 rounded-lg bg-yellow-500/10 border border-yellow-500/20" role="alert">
                                    <svg class="flex-shrink-0 inline w-5 h-5 mr-3" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"></path></svg>
                                    <div>
                                        <span class="font-medium">Atenção:</span> Estes textos são usados apenas para a impressão e não são salvos no banco de dados. Configure antes de imprimir.
                                    </div>
                                </div>

                            </div>

                            <!-- PREVIEW TAB -->
                            <div v-show="activeTab === 'preview'" class="space-y-6">
                                
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
                                                     {{ (turma.alunos || []).length }} selecionados
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
                                            <div v-for="(aluno, idx) in turma.alunos" :key="idx" class="flex gap-3 text-sm text-secondary-300 py-1 border-b border-white/5 last:border-0 pl-4">
                                                <span class="w-8 text-right font-mono opacity-50">{{ Number(idx) + 1 }}.</span>
                                                <span class="text-white">{{ aluno.nome }}</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div v-if="!turmas || turmas.every((t: any) => !t.alunos || t.alunos.length === 0)" class="text-center py-10 opacity-50">
                                    Nenhum candidato aprovado encontrado.
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
                            Imprimir Lista
                        </button>

                    </div>

                </div>
            </div>
        </div>
    </div>
</template>


<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: rgba(255, 255, 255, 0.02);
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 3px;
}
.custom-scrollbar::-webkit-scrollbar-thumb:hover {
  background: rgba(255, 255, 255, 0.2);
}
</style>
