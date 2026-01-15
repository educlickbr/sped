<script setup lang="ts">
import { useToast } from '../../composables/useToast'
import { generateUuidFileName, fileToBase64, validateFile } from '../../utils/file'

const appStore = useAppStore()

const props = defineProps<{
  isOpen: boolean
  processo: any // Contains id_processo, id_turma, tipo_processo, tipo_candidatura, area_curso
}>()

const emit = defineEmits(['close', 'completed'])

const { showToast } = useToast()

const isLoading = ref(false)
const formData = ref<any[]>([])
const answers = ref<Record<string, any>>({})
const fileNames = ref<Record<string, string>>({})
const files = ref<Record<string, File | null>>({})
const confirmDeletes = ref<Record<string, boolean>>({})

// Fetch Data via BFF
const fetchData = async () => {
    if (!props.processo) return
    
    isLoading.value = true
    try {
        const { data, error } = await useFetch('/api/aluno/documentos', {
            params: {
                tipo_processo: props.processo.tipo_processo,
                area: props.processo.area_curso,
                tipo_candidatura: props.processo.tipo_candidatura,
                id_turma: props.processo.id_turma
            }
        })

        if (error.value) throw error.value

        formData.value = (data.value as any[]) || []
        
        // Populate state
        formData.value.forEach((q: any) => {
            if (q.resposta || q.arquivo_original) {
                fileNames.value[q.id_pergunta] = q.arquivo_original || 'Arquivo Enviado'
                answers.value[q.id_pergunta] = q.resposta
            }
        })

    } catch (e: any) {
        console.error('Error fetching documents:', e)
        showToast('Erro ao carregar documentos', { type: 'error' })
    } finally {
        isLoading.value = false
    }
}

watch(() => props.isOpen, async (val) => {
    if (val) {
        await appStore.refreshHash()
        fetchData()
    } else {
        formData.value = []
        answers.value = {}
        fileNames.value = {}
    }
})

// File Handlers
const getFileTypes = (question: any): string[] => {
    if (question.pergunta === 'sua_foto') {
        return ['image/jpeg', 'image/png', 'image/jpg']
    }
    return ['application/pdf']
}

const triggerFileUpload = (questionId: string) => {
    const el = document.getElementById(`file-${questionId}`)
    if (el) el.click()
}

const handleFileChange = async (event: Event, question: any) => {
    const target = event.target as HTMLInputElement
    if (target.files && target.files.length > 0) {
        const file = target.files[0]
        if (!file) return

        const allowedTypes = getFileTypes(question)
        const { valid, error } = validateFile(file, allowedTypes)
        
        if (!valid) {
            showToast(error || 'Arquivo inválido', { type: 'error' })
            target.value = ''
            return
        }

        question.uploading = true
        fileNames.value[question.id_pergunta] = file.name
        
        try {
            const uuidName = generateUuidFileName(file.name)
            const base64 = await fileToBase64(file)

            await $fetch('/api/aluno/upload', {
                method: 'POST',
                body: {
                    id_turma: props.processo.id_turma,
                    id_pergunta: question.id_pergunta,
                    fileName: uuidName,
                    originalName: file.name,
                    fileBase64: base64
                }
            })

            files.value[question.id_pergunta] = file
            answers.value[question.id_pergunta] = uuidName 
            showToast('Arquivo enviado com sucesso!', { type: 'info' })
            
            // Mark question as answered in local state if needed
            question.resposta = uuidName

        } catch (err) {
            console.error('Upload Error:', err)
            showToast('Falha no upload. Tente novamente.', { type: 'error' })
            fileNames.value[question.id_pergunta] = ''
            target.value = ''
        } finally {
            question.uploading = false
        }
    }
}

const showConfirmDelete = (question: any) => {
    confirmDeletes.value[question.id_pergunta] = true
}

const performDeleteFile = async (question: any) => {
    question.deleting = true
    try {
        await $fetch('/api/aluno/delete-file', {
            method: 'POST',
            body: {
                id_turma: props.processo.id_turma,
                id_pergunta: question.id_pergunta,
                fileName: answers.value[question.id_pergunta]
            }
        })

        files.value[question.id_pergunta] = null
        fileNames.value[question.id_pergunta] = ''
        answers.value[question.id_pergunta] = null
        question.resposta = null

        const el = document.getElementById(`file-${question.id_pergunta}`) as HTMLInputElement
        if (el) el.value = ''

        confirmDeletes.value[question.id_pergunta] = false
        showToast('Arquivo removido!', { type: 'info' })

    } catch (err) {
        console.error('Delete Error:', err)
        showToast('Erro ao excluir arquivo.', { type: 'error' })
    } finally {
        question.deleting = false
    }
}

const isSaving = ref<Record<string, boolean>>({})

const handleSaveAnswer = async (question: any) => {
    isSaving.value[question.id_pergunta] = true
    try {
        await $fetch('/api/aluno/save-answer', {
            method: 'POST',
            body: {
                id_pergunta: question.id_pergunta,
                resposta: answers.value[question.id_pergunta],
                id_turma: props.processo.id_turma
            }
        })
        showToast('Link salvo com sucesso!', { type: 'info' })
    } catch (err) {
        console.error('Save Error:', err)
        showToast('Erro ao salvar link.', { type: 'error' })
    } finally {
        isSaving.value[question.id_pergunta] = false
    }
}
</script>

<template>
  <div v-if="isOpen" class="relative z-50" aria-labelledby="modal-title" role="dialog" aria-modal="true">
    <div class="fixed inset-0 bg-black/80 backdrop-blur-sm transition-opacity" @click="$emit('close')"></div>

    <div class="fixed inset-0 z-10 overflow-y-auto">
      <div class="flex min-h-full items-center justify-center p-0 text-center sm:p-0">
        <div class="relative transform overflow-hidden rounded-none md:rounded-xl bg-[#16161E] border-x-0 border-y-0 md:border md:border-white/10 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-3xl p-4 md:p-6" @click.stop>
            
            <div class="flex items-center justify-between mb-4 md:mb-6 border-b border-white/10 pb-4">
                <h3 class="text-lg md:text-xl font-bold text-white">
                    Envio de Documentos
                    <span class="block text-xs md:text-sm text-secondary-500 font-normal mt-1">{{ processo?.nome_curso }}</span>
                </h3>
                <button @click="$emit('close')" class="text-secondary-400 hover:text-white transition-colors">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                </button>
            </div>

            <div v-if="isLoading" class="flex justify-center py-20">
                <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-primary"></div>
            </div>

            <div v-else class="space-y-4 md:space-y-6 max-h-[80vh] overflow-y-auto pr-2 custom-scrollbar">
                <!-- Helper Text -->
                <div class="bg-blue-500/10 border border-blue-500/20 rounded-lg p-3 md:p-4 mb-2 md:mb-4">
                    <p class="text-[10px] md:text-xs text-blue-200">
                        Envie os documentos solicitados abaixo. Os arquivos devem estar em formato PDF (exceto a foto, que pode ser JPG/PNG). Certifique-se de que estão legíveis.
                    </p>
                </div>

                <div v-for="question in formData" :key="question.id_pergunta" class="flex flex-col gap-1.5 md:gap-2">
                    <label class="text-xs md:text-sm font-bold text-white flex justify-between">
                        <span>
                            {{ question.label }}
                            <span v-if="question.obrigatorio" class="text-primary">*</span>
                        </span>
                        <span v-if="answers[question.id_pergunta]" class="text-xs font-bold text-emerald-400 flex items-center gap-1">
                             <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
                             Enviado
                        </span>
                        <span v-else class="text-xs font-bold text-orange-400 flex items-center gap-1">
                             Pendente
                        </span>
                    </label>

                    <!-- File Upload Component -->
                    <div 
                        v-if="question.tipo === 'arquivo'"
                        class="relative border-2 border-dashed border-white/10 rounded-xl p-4 transition-all hover:border-primary/40 hover:bg-primary/5 group text-center cursor-pointer"
                        @click="triggerFileUpload(question.id_pergunta)"
                        :class="{'border-emerald-500/30 bg-emerald-500/5': answers[question.id_pergunta]}"
                    >
                        <input 
                            :id="'file-' + question.id_pergunta"
                            type="file" 
                            class="hidden"
                            :accept="getFileTypes(question).join(',')"
                            @change="handleFileChange($event, question)"
                        />
                        
                        <div v-if="question.uploading" class="flex flex-col items-center justify-center py-2">
                            <div class="animate-spin rounded-full h-6 w-6 border-t-2 border-primary mb-2"></div>
                            <span class="text-xs text-primary font-bold">Enviando...</span>
                        </div>

                        <div v-else-if="!fileNames[question.id_pergunta]" class="flex items-center justify-center gap-3 py-2">
                            <div class="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center group-hover:scale-110 transition-transform">
                                <svg class="w-4 h-4 text-primary" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="17 8 12 3 7 8"></polyline><line x1="12" y1="3" x2="12" y2="15"></line></svg>
                            </div>
                            <div class="text-left">
                                <p class="text-xs font-bold text-secondary-400">Clique para selecionar</p>
                                <p class="text-[10px] text-secondary-500/40">
                                    {{ question.pergunta === 'sua_foto' ? 'JPG, PNG' : 'PDF' }}
                                </p>
                            </div>
                        </div>

                        <div v-else class="flex items-center justify-between w-full py-1 px-2">
                            <div v-if="!confirmDeletes[question.id_pergunta]" class="flex items-center gap-3 flex-grow overflow-hidden">
                                <div class="w-8 h-8 rounded-full bg-emerald-500/10 flex items-center justify-center flex-shrink-0">
                                    <svg class="w-4 h-4 text-emerald-500" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"></path></svg>
                                </div>
                                <span class="text-xs font-bold text-white truncate">{{ fileNames[question.id_pergunta] }}</span>
                            </div>

                            <div v-if="!confirmDeletes[question.id_pergunta]" class="flex items-center gap-2 flex-shrink-0">
                                <a 
                                    v-if="answers[question.id_pergunta]"
                                    :href="appStore.hash_base ? `${appStore.hash_base}/${answers[question.id_pergunta]}` : '#'" 
                                    target="_blank"
                                    class="text-[10px] font-black uppercase tracking-widest text-primary hover:underline bg-primary/10 px-2 py-1 rounded"
                                    @click.stop
                                >
                                    Ver
                                </a>
                                <button 
                                    type="button" 
                                    class="text-[10px] font-black uppercase tracking-widest text-red-400 hover:underline px-2 py-1"
                                    @click.stop="showConfirmDelete(question)"
                                    :disabled="question.deleting"
                                >
                                    Excluir
                                </button>
                            </div>

                            <div v-else class="w-full flex items-center justify-between bg-red-500/10 rounded-lg p-2 px-3">
                                <span class="text-xs font-bold text-red-400">Confirmar exclusão?</span>
                                <div class="flex gap-2">
                                     <button 
                                        type="button"
                                        class="text-xs font-bold text-white hover:text-red-400 transition-colors"
                                        @click.stop="performDeleteFile(question)"
                                    >
                                        Sim
                                    </button>
                                    <button 
                                        type="button"
                                        class="text-xs text-secondary-400 hover:text-white transition-colors"
                                        @click.stop="confirmDeletes[question.id_pergunta] = false"
                                    >
                                        Não
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Link/Text Component -->
                    <div v-else-if="question.tipo === 'link'" class="flex gap-2">
                        <input 
                            type="text" 
                            v-model="answers[question.id_pergunta]"
                            placeholder="Cole o link do vídeo aqui (YouTube, Drive, etc)"
                            class="flex-grow bg-[#0f0f15] border border-white/10 rounded-lg px-4 py-3 text-sm text-white focus:outline-none focus:ring-1 focus:ring-primary focus:border-primary transition-all placeholder-secondary-500/50"
                        />
                        <button 
                            @click="handleSaveAnswer(question)"
                            :disabled="isSaving[question.id_pergunta] || !answers[question.id_pergunta]"
                            class="p-3 rounded-lg bg-primary/10 hover:bg-primary/20 text-primary transition-all flex-shrink-0 disabled:opacity-50"
                            title="Salvar Link"
                        >
                             <svg v-if="isSaving[question.id_pergunta]" class="w-7 h-7 animate-spin" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                             <svg v-else class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5">
                                <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path>
                                <polyline points="17 21 17 13 7 13 7 21"></polyline>
                                <polyline points="7 3 7 8 15 8"></polyline>
                             </svg>
                        </button>
                    </div>
                </div>
            </div>

            <div class="mt-6 flex justify-end">
                <button 
                    @click="$emit('close')"
                    class="px-6 py-2 bg-white/5 hover:bg-white/10 text-white font-bold rounded-lg transition-colors border border-white/10"
                >
                    Fechar
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
  background: rgba(255, 255, 255, 0.05);
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 10px;
}
</style>
