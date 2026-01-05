<script setup>
definePageMeta({
  layout: false
})

import ManagerListItem from '@/components/ManagerListItem.vue'
import ManagerDashboard from '@/components/ManagerDashboard.vue'
import ModalGerenciarEscola from '@/components/ModalGerenciarEscola.vue'
import ModalGerenciarPredio from '@/components/ModalGerenciarPredio.vue'
import ModalGerenciarSala from '@/components/ModalGerenciarSala.vue'
import ModalGerenciarEstante from '@/components/ModalGerenciarEstante.vue'
import ModalConfirmacao from '@/components/ModalConfirmacao.vue'
import { useToastStore } from '@/stores/toast'

const supabase = useSupabaseClient()
const store = useAppStore()
const toast = useToastStore()
const route = useRoute()
const router = useRouter()

// --- Tabs Config ---
const TABS = [
  { id: 'escolas', label: 'Escolas', icon: '🏫', rpc: 'escolas_get_paginado' },
  { id: 'predios', label: 'Prédios', icon: '🏢', rpc: 'bbtk_dim_predio_get_paginado' },
  { id: 'salas', label: 'Salas', icon: '🚪', rpc: 'bbtk_dim_sala_get_paginado' },
  { id: 'estantes', label: 'Estantes', icon: '📚', rpc: 'bbtk_dim_estante_get_paginado' }
]

const currentTabId = ref(route.query.tab || 'escolas')
const currentTab = computed(() => TABS.find(t => t.id === currentTabId.value) || TABS[0])

// --- Search & Pagination ---
const search = ref('')
const page = ref(1)
const limit = ref(10)

// --- Modal States ---
const isModalOpen = ref(false)
const selectedItem = ref(null)
const isConfirmOpen = ref(false)
const itemToDelete = ref(null)
const isDeleting = ref(false)

// --- BFF Data Fetching (SSR Friendly) ---
const { data: bffData, pending, error: bffError, refresh } = await useFetch(() => `/api/infra/${currentTabId.value}`, {
  query: computed(() => ({
    id_empresa: store.company?.empresa_id,
    pagina: page.value,
    limite: limit.value,
    busca: search.value || null
  })),
  watch: [currentTabId, page, search, () => store.company?.empresa_id],
  immediate: true
})

// Bind BFF data to local refs for easier template usage
const items = computed(() => bffData.value?.items || [])
const total = computed(() => bffData.value?.total || 0)
const pages = computed(() => bffData.value?.pages || 0)
const isLoading = computed(() => pending.value)

// Watchers for Route Sync
watch(currentTabId, (newId) => {
  page.value = 1
  search.value = ''
  router.push({ query: { ...route.query, tab: newId } })
})

// --- Methods ---
const switchTab = (tabId) => {
  currentTabId.value = tabId
}

const handleNew = () => {
  selectedItem.value = null
  isModalOpen.value = true
}

const handleEdit = (item) => {
  selectedItem.value = item
  isModalOpen.value = true
}

const handleDelete = (item) => {
  itemToDelete.value = item
  isConfirmOpen.value = true
}

const confirmDelete = async () => {
  if (!itemToDelete.value) return
  isDeleting.value = true
  try {
    const data = await $fetch(`/api/infra/${currentTabId.value}`, {
      method: 'DELETE',
      body: {
        id: itemToDelete.value.id,
        uuid: itemToDelete.value.uuid,
        id_empresa: store.company.empresa_id
      }
    })
    
    if (data && data.success) {
      toast.showToast('Registro excluído com sucesso!')
      isConfirmOpen.value = false
      itemToDelete.value = null
      refresh()
    } else {
        toast.showToast(data?.message || 'Erro ao excluir registro.', 'error')
    }
  } catch (err) {
    console.error('Erro ao excluir:', err)
    toast.showToast(err.data?.message || err.message || 'Erro ao excluir registro.', 'error')
  } finally {
    isDeleting.value = false
  }
}

const handleSuccess = () => {
  refresh()
}

// Stats for Dashboard
const dashboardStats = computed(() => [
  { label: 'Total Registros', value: total.value },
  { label: 'Página Atual', value: page.value }
])

</script>

<template>
  <NuxtLayout name="manager">
    <!-- Header Icon Slot -->
    <template #header-icon>
      <div class="w-10 h-10 rounded bg-primary/10 text-primary flex items-center justify-center shrink-0">
        <template v-if="currentTabId === 'escolas'">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 21h18M5 21V7l8-4 8 4v14M8 14h1v4h-1zM12 14h1v4h-1zM16 14h1v4h-1z"/></svg>
        </template>
        <template v-else-if="currentTabId === 'predios'">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2"></rect><line x1="9" y1="22" x2="9" y2="22"></line><line x1="15" y1="22" x2="15" y2="22"></line><line x1="12" y1="22" x2="12" y2="22"></line><line x1="12" y1="18" x2="12" y2="18"></line><line x1="12" y1="14" x2="12" y2="14"></line><line x1="12" y1="10" x2="12" y2="10"></line><line x1="12" y1="6" x2="12" y2="6"></line></svg>
        </template>
        <template v-else-if="currentTabId === 'salas'">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 21h18M5 21V7l8-4 8 4v14M8 14h1v4h-1zM12 14h1v4h-1zM16 14h1v4h-1z"></path></svg>
        </template>
        <template v-else-if="currentTabId === 'estantes'">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="3" width="16" height="18" rx="2"></rect><line x1="4" y1="8" x2="20" y2="8"></line><line x1="4" y1="13" x2="20" y2="13"></line><line x1="4" y1="18" x2="20" y2="18"></line><line x1="9" y1="21" x2="9" y2="3"></line></svg>
        </template>
        <span v-else class="text-xl">{{ currentTab.icon }}</span>
      </div>
    </template>

    <!-- Header Title Slot -->
    <template #header-title>
      <span class="capitalize">{{ currentTab.label }}</span>
    </template>

    <!-- Header Subtitle Slot -->
    <template #header-subtitle>
      {{ total }} registros
    </template>

    <!-- Header Actions Slot -->
    <template #header-actions>
      <div class="relative w-full sm:max-w-[180px]">
        <input 
          type="text" 
          v-model="search" 
          placeholder="Buscar..." 
          class="w-full pl-8 pr-3 py-1.5 text-xs bg-background border border-secondary/30 rounded text-text focus:outline-none focus:border-primary transition-all placeholder:text-secondary/70 shadow-sm"
        >
        <div class="absolute left-2.5 top-1/2 -translate-y-1/2 text-secondary/70">
          <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
        </div>
      </div>

      <button @click="handleNew" class="bg-primary hover:bg-primary/90 text-white px-4 py-1.5 rounded text-xs font-bold transition-all shadow-sm hover:shadow-md flex items-center gap-1 shrink-0">
        <span>+</span> <span class="hidden sm:inline">Novo</span>
      </button>
    </template>

    <!-- Tabs Slot -->
    <template #tabs>
      <button
        v-for="tab in TABS"
        :key="tab.id"
        @click="switchTab(tab.id)"
        :class="[
          'relative px-4 py-3 text-sm font-bold transition-all whitespace-nowrap outline-none',
          currentTabId === tab.id ? 'text-primary' : 'text-secondary hover:text-text'
        ]"
      >
        {{ tab.label }}
        <div v-if="currentTabId === tab.id" class="absolute bottom-0 left-0 w-full h-[3px] bg-primary rounded-full" />
      </button>
    </template>

    <!-- Sidebar Slot -->
    <template #sidebar>
      <ManagerDashboard 
        :title="`Dashboard: ${currentTab.label}`" 
        :stats="dashboardStats"
      >
        <template #extra>
          <div class="bg-primary/5 p-4 rounded border border-primary/10">
            <h4 class="text-[10px] font-black text-primary uppercase tracking-[0.2em] mb-2">Acesso Rápido</h4>
            <p class="text-[11px] text-primary/70 leading-relaxed font-medium">
              Gerencie os recursos de infraestrutura da sua instituição. Clique em "Novo" para cadastrar ou selecione um item para editar.
            </p>
          </div>
        </template>
      </ManagerDashboard>
    </template>

    <!-- Default Content Slot -->
    <div v-if="isLoading && items.length === 0" class="flex flex-col items-center justify-center py-20 gap-4 opacity-50">
      <div class="w-8 h-8 border-2 border-primary/20 border-t-primary rounded-full animate-spin" />
      <p class="text-xs font-bold uppercase tracking-widest text-secondary">Carregando...</p>
    </div>

    <div v-else-if="items.length > 0" class="flex flex-col gap-2">
      <ManagerListItem
        v-for="item in items"
        :key="item.id || item.uuid"
        :title="item.nome"
        :id="item.id || item.uuid"
        @edit="handleEdit(item)"
        @delete="handleDelete(item)"
      >
        <template #metadata>
          <div class="flex items-center gap-1.5 text-[10px] font-medium tracking-wide group-hover:text-secondary/80 transition-colors">
            <!-- Breadcrumb Flow -->
            <template v-if="currentTabId === 'escolas'">
              <span class="opacity-70">{{ item.endereco || 'Sem endereço informado' }}</span>
            </template>
            
            <template v-else-if="currentTabId === 'predios'">
              <span class="text-primary/70 font-bold">{{ item.escola_nome || item.nome_escola }}</span>
            </template>

            <template v-else-if="currentTabId === 'salas'">
              <span class="text-primary/70 font-bold">{{ item.escola_nome || item.nome_escola }}</span>
              <span class="opacity-30">/</span>
              <span>{{ item.predio_nome || item.nome_predio }}</span>
            </template>

            <template v-else-if="currentTabId === 'estantes'">
              <span class="text-primary/70 font-bold uppercase tracking-widest text-[9px]">{{ item.escola_nome || item.nome_escola }}</span>
              <span class="opacity-30">/</span>
              <span class="opacity-80">{{ item.predio_nome || item.nome_predio }}</span>
              <span class="opacity-30">/</span>
              <span class="text-secondary">{{ item.sala_nome || item.nome_sala }}</span>
            </template>
          </div>
        </template>
        <template #icon>
          <div class="text-primary">
            <template v-if="currentTabId === 'escolas'">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M3 21h18M5 21V7l8-4 8 4v14M8 14h1v4h-1zM12 14h1v4h-1zM16 14h1v4h-1z"/></svg>
            </template>
            <template v-else-if="currentTabId === 'predios'">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2"></rect></svg>
            </template>
            <template v-else-if="currentTabId === 'salas'">
               <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M3 21h18M5 21V7l8-4 8 4v14M8 14h1v4h-1zM12 14h1v4h-1zM16 14h1v4h-1z"/></svg>
            </template>
            <template v-else-if="currentTabId === 'estantes'">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="3" width="16" height="18" rx="2"></rect><line x1="4" y1="8" x2="20" y2="8"></line><line x1="4" y1="13" x2="20" y2="13"></line></svg>
            </template>
          </div>
        </template>
      </ManagerListItem>

      <!-- Pagination -->
      <div class="flex items-center justify-center gap-4 mt-6 py-4">
        <button @click="page--" :disabled="page === 1" class="px-4 py-2 text-xs font-bold text-secondary disabled:opacity-30">Anterior</button>
        <span class="text-[11px] font-black bg-div-15 px-3 py-1 rounded-full border border-secondary/10">{{ page }} / {{ pages }}</span>
        <button @click="page++" :disabled="page >= pages" class="px-4 py-2 text-xs font-bold text-secondary disabled:opacity-30">Próxima</button>
      </div>
    </div>

    <div v-else class="flex flex-col items-center justify-center py-20 text-center text-secondary">
      <p>Nenhum registro encontrado.</p>
    </div>

    <template #modals>
      <ModalGerenciarEscola 
        v-if="currentTabId === 'escolas'"
        :is-open="isModalOpen"
        :initial-data="selectedItem"
        @close="isModalOpen = false"
        @success="handleSuccess"
      />

      <ModalGerenciarPredio
        v-if="currentTabId === 'predios'"
        :is-open="isModalOpen"
        :initial-data="selectedItem"
        @close="isModalOpen = false"
        @success="handleSuccess"
      />

      <ModalGerenciarSala
        v-if="currentTabId === 'salas'"
        :is-open="isModalOpen"
        :initial-data="selectedItem"
        @close="isModalOpen = false"
        @success="handleSuccess"
      />

      <ModalGerenciarEstante
        v-if="currentTabId === 'estantes'"
        :is-open="isModalOpen"
        :initial-data="selectedItem"
        @close="isModalOpen = false"
        @success="handleSuccess"
      />

      <ModalConfirmacao
        :is-open="isConfirmOpen"
        title="Excluir Registro?"
        :message="`Deseja realmente excluir <b>${itemToDelete?.nome}</b>?<br>Esta ação não pode ser desfeita.`"
        confirm-text="Sim, excluir"
        :is-loading="isDeleting"
        @close="isConfirmOpen = false"
        @confirm="confirmDelete"
      />
    </template>
  </NuxtLayout>
</template>
