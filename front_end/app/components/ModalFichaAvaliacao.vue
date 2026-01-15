<script setup lang="ts">
import { useToast } from '../../composables/useToast';

const props = defineProps<{
    isOpen: boolean;
    area: string;
    anoSemestre: string;
}>();

const emit = defineEmits(['close']);
const { showToast } = useToast();

const isLoading = ref(false);
const activeTab = ref<'config' | 'preview'>('config');
const dataInicio = ref('');

// Data State
const turmas = ref<any[]>([]);

const nomeProcesso = computed(() => {
    if (!props.anoSemestre) return '';
    let year = props.anoSemestre.substring(0, 2);
    let semester = props.anoSemestre.includes('IIs') ? '2' : '1';
    return `20${year}.${semester}`;
});

// Fetch Data
const fetchData = async () => {
    if (!props.isOpen) return;

    isLoading.value = true;
    try {
        const data = await $fetch('/api/selecao/fichas-avaliacao', {
            params: {
              area: props.area,
              anoSemestre: props.anoSemestre,
              dataInicio: dataInicio.value || undefined
            }
        });
        
        turmas.value = ((data as any[]) || []).map((t: any) => ({
            ...t,
            custom_pergunta_1: t.pergunta_1 || '',
            custom_pergunta_2: t.pergunta_2 || '',
            custom_pergunta_3: t.pergunta_3 || '',
            custom_rodape: t.rodape || '',
            isExpanded: false,
            isPreviewExpanded: false,
            isSaving: false,
            lastSaved: null
        })).sort((a: any, b: any) => a.nome_turma.localeCompare(b.nome_turma));

    } catch (e) {
        console.error('Error fetching fichas:', e);
        showToast('Erro ao buscar fichas de avaliação.', { type: 'error' });
    } finally {
        isLoading.value = false;
    }
};

const saveParams = async (turma: any) => {
    if (!turma.id_curso) {
        console.error('Missing id_curso for turma:', turma);
        return;
    }

    turma.isSaving = true;
    try {
        await $fetch('/api/selecao/ficha-avaliacao-config', {
            method: 'POST',
            body: {
                id_curso: turma.id_curso,
                pergunta_1: turma.custom_pergunta_1,
                pergunta_2: turma.custom_pergunta_2,
                pergunta_3: turma.custom_pergunta_3,
                rodape: turma.custom_rodape
            }
        });
        
        turma.lastSaved = new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
    } catch (e) {
        console.error('Error saving params:', e);
        showToast('Erro ao salvar configurações da ficha.', { type: 'error' });
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
    const turmasToPrint = items.length > 0 ? items : turmas.value;

    // Generate HTML based on current state
    const htmlContent = generateFullHTML(turmasToPrint);
    
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

    // Safe access to doc
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
    * { box-sizing: border-box; font-family: 'Poppins', Arial, sans-serif; color: #222; font-size: 12.5px; }
    body { margin: 0; padding: 0; }
    .pagina { width: 100%; padding: 10mm 12mm; }
    .pagina + .pagina { page-break-before: always; }
    
    /* BLOCO 1: TOPO */
    .bloco-topo { margin-bottom: 6mm; }
    .linha-topo { display: grid; grid-template-columns: 1fr 2fr 1fr; align-items: flex-start; gap: 10px; }
    .badge-area { font-size: 10px; text-transform: uppercase; font-weight: 600; border-radius: 12px; border: 1px solid #333; padding: 4px 10px; display: inline-block; white-space: nowrap; justify-self: start; }
    .topo-centro { text-align: center; font-size: 13px; justify-self: center; flex: 1; }
    .logo-area { width: 100%; max-width: 130px; height: auto; justify-self: end; }
    .logo-area img { max-width: 100%; height: auto; display: block; }
    .topo-centro .linha1 { font-weight: 500; margin-bottom: 3px; }
    .topo-centro .linha2 { font-weight: 700; font-size: 16px; margin-bottom: 3px; }
    .topo-centro .linha3 { font-weight: 600; margin-bottom: 3px; }
    .topo-centro .linha4 { font-size: 12px; font-style: italic; }

    /* BLOCO 2: DADOS CANDIDATO */
    .bloco-candidato { margin-bottom: 6mm; }
    .linha-cabecalho-ficha { display: flex; justify-content: space-between; }
    .bloco-num-classificacao { width: 32mm; height: 26mm; border: 1.5px solid #000; border-radius: 4px; display: flex; align-items: center; justify-content: center; font-size: 30px; font-weight: 700; }
    .bloco-dados-candidato { flex: 1; margin-left: 14px; font-size: 12.5px; }
    .bloco-dados-candidato .linha { margin-bottom: 4px; }
    .bloco-dados-candidato strong { font-weight: 600; }

    /* BLOCO 3: PERGUNTAS INICIAIS */
    .bloco-perguntas-iniciais { margin-bottom: 6mm; }
    .bloco-pergunta { margin-bottom: 6mm; }
    .bloco-pergunta:last-child { margin-bottom: 0; }
    .faixa-cinza { background: #f0f0f0; border-radius: 8px; padding: 5px 10px; font-size: 12px; margin-bottom: 4px; line-height: 1.4; }
    .linha-opcoes { display: flex; gap: 20px; margin-bottom: 2px; font-size: 12px; padding-left: 10px; }
    .checkbox-falso { display: inline-block; width: 10px; height: 10px; border: 1px solid #000; margin-right: 5px; vertical-align: middle; }

    /* BLOCO 4: TABELA AVALIAÇÃO */
    .bloco-avaliacao { margin-bottom: 6mm; }
    .titulo-secao { text-align: center; font-size: 12.5px; font-weight: 600; margin-bottom: 4mm; }
    .tabela-criterios { width: 100%; border-collapse: collapse; font-size: 11.5px; }
    .tabela-criterios th, .tabela-criterios td { border: 0.6px solid #555; padding: 5px 6px; vertical-align: middle; }
    .tabela-criterios th { font-weight: 600; text-align: left; }
    .col-av { width: 28mm; text-align: center; }
    .col-med { width: 20mm; text-align: center; }

    /* BLOCO 5: NOTA FINAL + CONSIDERAÇÕES */
    .bloco-nota-consideracoes { margin-bottom: 6mm; }
    .linha-nota-consideracoes { display: flex; gap: 8mm; }
    .col-consideracoes { flex: 4; }
    .titulo-consideracoes { font-weight: 600; margin-bottom: 5px; font-size: 12.5px; }
    .linha-cons { border-top: 0.6px solid #555; height: 8mm; margin-bottom: 3mm; }
    .col-nota-final { flex: 1; }
    .titulo-nota-final { font-weight: 700; margin-bottom: 5px; font-size: 12.5px; }
    .box-nota-final { width: 24mm; height: 14mm; border: 1px solid #000; }

    /* BLOCO 6: ASSINATURAS */
    .bloco-assinaturas { margin-bottom: 10mm; }
    .assinaturas { display: flex; justify-content: center; gap: 35mm; font-size: 12px; text-align: center; }
    .assinatura-col { flex: 0 0 auto; }
    .assinatura-linha { border-top: 0.6px solid #555; width: 50mm; margin-bottom: 3px; }

    /* BLOCO 7: RODAPÉ */
    .bloco-rodape { margin-top: auto; }
    .rodape-perfil { font-size: 11px; text-align: center; line-height: 1.3; }
    .rodape-titulo { font-weight: 700; margin-bottom: 2px; }
    .rodape-texto { font-weight: 400; }
    
    @page { size: A4; margin: 0; }
    html, body { width: 210mm; background: white; }
`;

const generateBody = (items: any[]) => {
    // Helpers
    const fmt = (v: any) => v ? v : '';
    const upper = (v: any) => v ? String(v).toUpperCase() : '';
    const formatDate = (dateStr: string) => {
        if (!dateStr) return '';
        if (dateStr.includes('/')) return dateStr;
        if (dateStr.includes('-')) {
             const parts = (dateStr.split('T')[0] || '').split('-');
             if (parts.length === 3) return `${parts[2]}/${parts[1]}/${parts[0]}`;
        }
        return dateStr;
    };

    const tituloProcesso = `Processo seletivo ${props.anoSemestre || ''}`;
    const subtituloProcesso = '';

    return items.map((t) => {
        if (!Array.isArray(t.alunos) || t.alunos.length === 0) return '';
        
        // Use custom values if edited, else DB values
        const pergunta1 = t.custom_pergunta_1;
        const pergunta2 = t.custom_pergunta_2;
        const pergunta3 = t.custom_pergunta_3;
        
        // Rodape
        const textoRodapeRaw = `Perfil do Curso de ${t.nome_turma}:\n${t.custom_rodape || ''}`.trim();
        const [rodapeTitulo, ...rodapeTextoArray] = textoRodapeRaw.split('\n');
        const rodapeTexto = rodapeTextoArray.join(' ').trim();

        return t.alunos.map((aluno: any) => {
             const classificacao = String(aluno.classificacao || '').padStart(3, '0');
             
             return `
                <div class="pagina">
                  <!-- BLOCO 1: TOPO -->
                  <div class="bloco-topo">
                    <div class="linha-topo">
                      <div class="badge-area">${props.area}</div>
                      <div class="topo-centro">
                        <div class="linha1">${tituloProcesso} ${subtituloProcesso}</div>
                        <div class="linha2">Ficha de Avaliação</div>
                        <div class="linha3">${fmt(t.nome_turma)}</div>
                        <div class="linha4">(${fmt(t.turno)})</div>
                      </div>
                      <div class="logo-area">
                        <img src="https://spedppull.b-cdn.net/site/sped_logo_total%20(1).png" alt="Logo SPED">
                      </div>
                    </div>
                  </div>

                  <!-- BLOCO 2: DADOS DO CANDIDATO -->
                  <div class="bloco-candidato">
                    <div class="linha-cabecalho-ficha">
                      <div class="bloco-num-classificacao">${classificacao}</div>
                      <div class="bloco-dados-candidato">
                        <div class="linha"><strong>Nome completo:</strong> ${upper(aluno.nome)}</div>
                        <div class="linha"><strong>Data da Prova: </strong>${formatDate(t.data_prova)}</div>
                        <div class="linha"><strong>Etnia: </strong> ${fmt(aluno.cor_raca)}</div>
                        <div class="linha"><strong>Gênero: </strong> ${fmt(aluno.identidade_genero)}</div>
                        <div class="linha"><strong>Cursar sem bolsa? </strong> ${fmt(aluno.condicao_receber_bolsa)}</div>
                        <div class="linha"><strong>Experiência na área?: </strong> ________</div>
                        <div class="linha"><strong>Renda per capita: </strong> ${fmt(aluno.renda_per_capita)}</div>
                      </div>
                    </div>
                  </div>

                  <!-- BLOCO 3: PERGUNTAS INICIAIS -->
                  <div class="bloco-perguntas-iniciais">
                    <div class="bloco-pergunta">
                      <div class="faixa-cinza">Tem disponibilidade para frequentar o curso conforme os horários estabelecidos?</div>
                      <div class="linha-opcoes">
                        <span><span class="checkbox-falso"></span>Sim</span>
                        <span><span class="checkbox-falso"></span>Não</span>
                      </div>
                    </div>
                    <div class="bloco-pergunta">
                      <div class="faixa-cinza">É a sua 1ª vivência com o curso?</div>
                      <div class="linha-opcoes">
                        <span><span class="checkbox-falso"></span>Sim</span>
                        <span><span class="checkbox-falso"></span>Não</span>
                      </div>
                    </div>
                    <div class="bloco-pergunta">
                      <div class="faixa-cinza">Qual a expectativa em relação ao curso?</div>
                      <div class="linha-opcoes">
                        <span><span class="checkbox-falso"></span>Complementar a formação?</span>
                        <span><span class="checkbox-falso"></span>Se preparar para o mercado de trabalho?</span>
                      </div>
                    </div>
                  </div>

                  <!-- BLOCO 4: TABELA DE AVALIAÇÃO -->
                  <div class="bloco-avaliacao">
                    <div class="titulo-secao">Vivência prática - Critérios de Avaliação (Nota de 0 a 10)</div>
                    <table class="tabela-criterios">
                      <tr>
                        <th>Pergunta</th>
                        <th class="col-av">Avaliador 1</th>
                        <th class="col-av">Avaliador 2</th>
                        <th class="col-med">Média</th>
                      </tr>
                      <tr>
                        <td>${fmt(pergunta1)}</td>
                        <td></td><td></td><td></td>
                      </tr>
                      <tr>
                        <td>${fmt(pergunta2)}</td>
                        <td></td><td></td><td></td>
                      </tr>
                      <tr>
                        <td>${fmt(pergunta3)}</td>
                        <td></td><td></td><td></td>
                      </tr>
                    </table>
                  </div>

                  <!-- BLOCO 5: NOTA FINAL + CONSIDERAÇÕES -->
                  <div class="bloco-nota-consideracoes">
                    <div class="linha-nota-consideracoes">
                      <div class="col-consideracoes">
                        <div class="titulo-consideracoes">Considerações:</div>
                        <div class="linha-cons"></div>
                        <div class="linha-cons"></div>
                        <div class="linha-cons"></div>
                      </div>
                      <div class="col-nota-final">
                        <div class="titulo-nota-final">Nota final</div>
                        <div class="box-nota-final"></div>
                      </div>
                    </div>
                  </div>

                  <!-- BLOCO 6: ASSINATURAS -->
                  <div class="bloco-assinaturas">
                    <div class="assinaturas">
                      <div class="assinatura-col">
                        <div class="assinatura-linha"></div>
                        Avaliador 1
                      </div>
                      <div class="assinatura-col">
                        <div class="assinatura-linha"></div>
                        Avaliador 2
                      </div>
                    </div>
                  </div>

                  <!-- BLOCO 7: RODAPÉ -->
                  <div class="bloco-rodape">
                    <div class="rodape-perfil">
                      <div class="rodape-titulo">${fmt(rodapeTitulo)}</div>
                      <div class="rodape-texto">${fmt(rodapeTexto)}</div>
                    </div>
                  </div>
                </div>
             `;
        }).join('');
    }).join('');
};

const generateFullHTML = (items: any[]) => {
    return `
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <title>Fichas de Avaliação</title>
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
                        Gerar Fichas de Avaliação
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
                    Configurar Ficha
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
                                     
                                     <!-- Perguntas -->
                                     <div class="space-y-4 mt-4">
                                         <div v-for="i in 3" :key="i">
                                              <label class="block text-xs font-bold text-secondary mb-1">Pergunta {{ i }}</label>
                                              <div class="flex gap-2">
                                                 <input 
                                                    v-model="turma[`custom_pergunta_${i}`]" 
                                                    @blur="saveParams(turma)"
                                                    class="w-full bg-[#0f0f15] border border-white/10 rounded px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" 
                                                    :placeholder="`Digite a pergunta ${i}...`" 
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

                                         <!-- Rodapé -->
                                         <div>
                                              <label class="block text-xs font-bold text-secondary mb-1">Rodapé</label>
                                              <div class="flex gap-2">
                                                 <textarea 
                                                    v-model="turma.custom_rodape" 
                                                    @blur="saveParams(turma)"
                                                    class="w-full bg-[#0f0f15] border border-white/10 rounded px-3 py-2 text-sm text-white focus:border-primary focus:outline-none min-h-[120px]" 
                                                    placeholder="Texto do rodapé..." 
                                                 ></textarea>
                                                 <button @click="saveParams(turma)" class="text-primary hover:text-primary-600 transition-colors p-1 self-start" title="Salvar">
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
                                <div v-if="!turma.alunos || turma.alunos.length === 0" class="text-xs text-secondary/5 italic py-2">
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
                    Imprimir Fichas
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
