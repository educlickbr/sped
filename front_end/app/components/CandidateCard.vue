<script setup lang="ts">
const appStore = useAppStore(); // Auto-imported from Pinia

interface Candidato {
  id_processo: string;
  nome_completo: string;
  nome_social?: string;
  nome_artistico?: string;
  criado_em: string;
  genero?: string;
  raca?: string;
  data_nascimento?: string;
  imagem_user?: string;
  status_processo: string;
  // Badges logic
  pcd?: string;
  laudo_enviado?: boolean;
  nota_total_processo?: number;
  deferimento?: string;
}

const props = defineProps<{
  candidato: Candidato;
}>();

const emit = defineEmits(['action']);

const imageUrl = computed(() => {
    // Logic: hash_base (from me.ts/Bunny) + image path
    // If image starts with http, use it directly (e.g. google auth photo)
    if (props.candidato.imagem_user?.startsWith('http')) return props.candidato.imagem_user;
    
    // If we have a hash_base and an image path, construct the Bunny URL
    if (appStore.hash_base && props.candidato.imagem_user) {
        return `${appStore.hash_base}${props.candidato.imagem_user}`;
    }

    return 'https://via.placeholder.com/150';
});

const formattedDate = computed(() => {
    return new Date(props.candidato.criado_em).toLocaleString('pt-BR', {
        day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit'
    }) + 'Hs';
});

const isPcd = computed(() => {
    const val = props.candidato.pcd?.toLowerCase() || '';
    return val.includes('sim');
});

const statusColor = computed(() => {
    const s = (props.candidato.status_processo || '').toLowerCase();
    switch (s) {
        case 'aprovado': return 'text-emerald-400 border-emerald-400/30 bg-emerald-400/10'; // SUCCESS
        case 'recusado': return 'text-red-400 border-red-400/30 bg-red-400/10'; // DANGER
        case 'suplente': return 'text-purple-400 border-purple-400/30 bg-purple-400/10'; // PRIMARY
        case 'aguardando': 
        default: return 'text-gray-400 border-gray-400/30 bg-gray-400/10'; // PENDENTE (Gray)
    }
});

const deferimentoColor = computed(() => {
    const d = (props.candidato.deferimento || '').toLowerCase();
    if (d.includes('indeferida')) return 'text-red-400 border-red-400/30 bg-red-400/10';
    if (d.includes('deferida')) return 'text-green-400 border-green-400/30 bg-green-400/10';
    return 'text-gray-400 border-gray-400/30 bg-gray-400/10';
});

const formattedScore = computed(() => {
    if (!props.candidato.nota_total_processo) return null;
    return (props.candidato.nota_total_processo / 100).toFixed(1);
});

const age = computed(() => {
    if (!props.candidato.data_nascimento) return null;
    const birthDate = props.candidato.data_nascimento;
    
    // Robust parsing
    let birth: Date;
    if (birthDate.includes('/')) {
        const parts = birthDate.split('/');
        // Assumes DD/MM/YYYY
        birth = new Date(`${parts[2]}-${parts[1]}-${parts[0]}`);
    } else {
        birth = new Date(birthDate);
    }
    
    if (isNaN(birth.getTime())) return null;

    const today = new Date();
    let years = today.getFullYear() - birth.getFullYear();
    const m = today.getMonth() - birth.getMonth();
    if (m < 0 || (m === 0 && today.getDate() < birth.getDate())) {
        years--;
    }
    return years;
});
</script>

<template>
  <!-- MOBILE: CRM Pattern | DESKTOP: Original Horizontal -->
  <div class="bg-[#16161E] border border-white/5 rounded-xl overflow-hidden md:overflow-visible hover:border-white/10 transition-all duration-300 hover:shadow-lg hover:shadow-black/20">
    
    <!-- ========== MOBILE LAYOUT (< md) ========== -->
    <div class="md:hidden">
      <!-- Compact Header: Photo + Name + Status (Single Line) -->
      <div class="p-3 flex items-center gap-3 border-b border-white/5">
        <!-- Small Avatar (40px) -->
        <div class="relative flex-shrink-0">
          <img :src="imageUrl" alt="Foto" class="w-10 h-10 rounded-full object-cover border-2 border-white/10" />
          <div v-if="formattedScore" class="absolute -top-1 -right-1 bg-primary text-white text-[9px] font-bold rounded-full w-5 h-5 flex items-center justify-center">
            {{ formattedScore }}
          </div>
        </div>

        <!-- Name + Date + Mini Info -->
        <div class="flex-grow min-w-0">
          <h3 class="text-sm font-bold text-white truncate leading-tight">
            {{ candidato.nome_completo }}
          </h3>
          <p class="text-[10px] text-secondary-500 truncate">
            {{ formattedDate }}
          </p>
          <!-- Gênero/Raça inline abaixo do nome -->
          <div class="flex gap-2 mt-0.5 text-[10px] text-gray-400">
            <span v-if="candidato.genero">{{ candidato.genero }}</span>
            <span v-if="candidato.genero && candidato.raca">•</span>
            <span v-if="candidato.raca">{{ candidato.raca }}</span>
            <span v-if="candidato.raca">{{ candidato.raca }}</span>
            <span v-if="age">• {{ age }}a</span>
          </div>
        </div>

        <!-- Status Badge -->
        <div class="flex-shrink-0 flex items-center gap-1">
          <span class="px-2 py-1 rounded text-[9px] font-bold border uppercase tracking-wide" :class="statusColor">
            {{ candidato.status_processo || 'Pendente' }}
          </span>
           <span v-if="candidato.deferimento" class="px-2 py-1 rounded text-[9px] font-bold border uppercase tracking-wide" :class="deferimentoColor">
            {{ candidato.deferimento }}
          </span>
        </div>
      </div>

      <!-- Data Section: Vertical List (apenas nomes sociais/artísticos) -->
      <div v-if="candidato.nome_social || candidato.nome_artistico || isPcd || candidato.laudo_enviado" class="p-3 space-y-1.5 text-xs border-b border-white/5">
        <!-- Tags -->
        <div v-if="isPcd || candidato.laudo_enviado" class="flex flex-wrap gap-1.5 mb-2">
          <span v-if="isPcd" class="px-2 py-0.5 rounded-full text-[9px] uppercase font-bold bg-blue-500/10 text-blue-400 border border-blue-500/20">PCD</span>
          <span v-if="candidato.laudo_enviado" class="px-2 py-0.5 rounded-full text-[9px] uppercase font-bold bg-purple-500/10 text-purple-400 border border-purple-500/20">Laudo OK</span>
        </div>

        <!-- Data Rows (apenas nomes extras) -->
        <div v-if="candidato.nome_social" class="flex justify-between">
          <span class="text-secondary-600 text-[10px]">Nome Social</span>
          <span class="text-white font-medium truncate ml-2">{{ candidato.nome_social }}</span>
        </div>
        <div v-if="candidato.nome_artistico" class="flex justify-between">
          <span class="text-secondary-600 text-[10px]">Nome Artístico</span>
          <span class="text-white font-medium truncate ml-2">{{ candidato.nome_artistico }}</span>
        </div>
      </div>

      <!-- Actions: Grid layout (Matricular + Deletar top, 3 bottom) -->
      <div class="p-3">
        <div class="grid grid-cols-2 gap-2">
          <!-- Top Row: Matricular + Deletar (Equal prominence) -->
          <button @click="$emit('action', 'matricular', candidato)" 
            class="px-4 py-2.5 rounded-lg bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 text-sm font-semibold transition-all active:scale-[0.98] flex items-center justify-center gap-2">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
            <span class="text-xs">Matricular</span>
          </button>
          
          <button @click="$emit('action', 'deletar', candidato)" 
            class="px-4 py-2.5 rounded-lg bg-red-500/10 hover:bg-red-500/20 text-red-400 border border-red-500/30 text-sm font-semibold transition-all active:scale-[0.98] flex items-center justify-center gap-2">
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
            <span class="text-xs">Deletar</span>
          </button>

          <!-- Bottom Row: 3 Secondary Actions - Grid 3 cols, col-span-2 para ocupar ambas colunas -->
        </div>
        
        <div class="grid grid-cols-3 gap-2 mt-2">
          <button @click="$emit('action', 'dados', candidato)" 
            class="px-3 py-2 rounded-lg bg-white/5 hover:bg-white/10 text-white text-xs font-medium transition-all active:scale-[0.98] flex flex-col items-center gap-1">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path></svg>
            <span class="text-[10px]">Dados</span>
          </button>
          <button @click="$emit('action', 'documentos', candidato)" 
            class="px-3 py-2 rounded-lg bg-white/5 hover:bg-white/10 text-white text-xs font-medium transition-all active:scale-[0.98] flex flex-col items-center gap-1">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg>
            <span class="text-[10px]">Docs</span>
          </button>
          <button @click="$emit('action', 'avaliar', candidato)" 
            class="px-3 py-2 rounded-lg bg-white/5 hover:bg-white/10 text-white text-xs font-medium transition-all active:scale-[0.98] flex flex-col items-center gap-1">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path></svg>
            <span class="text-[10px]">Avaliar</span>
          </button>
        </div>
      </div>
    </div>

    <!-- ========== DESKTOP LAYOUT (>= md) - ORIGINAL ========== -->
    <div class="hidden md:flex md:flex-row gap-4 p-4">
      <!-- Left: Photo -->
      <div class="flex-shrink-0">
        <div class="w-32 h-32 rounded-lg border border-white/10 relative group hover:z-50">
          <img :src="imageUrl" alt="Foto do Candidato" class="w-full h-full object-cover rounded-lg transition-all duration-300 group-hover:scale-[2.5] group-hover:translate-x-16 group-hover:shadow-[0_0_30px_rgba(0,0,0,0.5)] bg-[#16161E]" />
          <div v-if="formattedScore" class="absolute top-0 right-0 bg-primary px-2 py-0.5 text-xs font-bold text-white rounded-bl-lg rounded-tr-lg transition-opacity duration-200 group-hover:opacity-0 pointer-events-none">
            Nota {{ formattedScore }}
          </div>
        </div>
      </div>

      <!-- Center: Info -->
      <div class="flex-grow flex flex-col justify-between">
        <div class="space-y-1">
          <div class="flex items-start justify-between">
            <div>
              <h3 class="text-lg font-bold text-white hover:text-primary transition-colors">
                {{ candidato.nome_completo }}
              </h3>
              <p class="text-xs text-secondary-500">
                Criado em: {{ formattedDate }}
              </p>
            </div>
            
            <!-- Status Badge (Top Right) -->
            <div class="flex items-center gap-2">
                <span class="px-2 py-1 rounded text-xs font-medium border uppercase tracking-wider" :class="statusColor">
                {{ candidato.status_processo || 'Pendente' }}
                </span>
                <span v-if="candidato.deferimento" class="px-2 py-1 rounded text-xs font-medium border uppercase tracking-wider" :class="deferimentoColor">
                {{ candidato.deferimento }}
                </span>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-x-4 gap-y-1 text-sm text-gray-400 mt-2">
            <p v-if="candidato.nome_social"><span class="text-secondary-600">Nome Social:</span> {{ candidato.nome_social }}</p>
            <p v-if="candidato.nome_artistico"><span class="text-secondary-600">Nome Artístico:</span> {{ candidato.nome_artistico }}</p>
            <p v-if="candidato.genero || candidato.raca">
              <span class="text-secondary-600">Gênero/Raça:</span> 
              {{ candidato.genero || '-' }} / {{ candidato.raca || '-' }}
            </p>
            <p v-if="age"><span class="text-secondary-600">Idade:</span> {{ age }} anos</p>
          </div>

          <!-- Tags -->
          <div class="flex flex-wrap gap-2 mt-2">
            <span v-if="isPcd" class="px-2 py-0.5 rounded-full text-[10px] uppercase font-bold bg-blue-500/10 text-blue-400 border border-blue-500/20">PCD</span>
            <span v-if="candidato.laudo_enviado" class="px-2 py-0.5 rounded-full text-[10px] uppercase font-bold bg-purple-500/10 text-purple-400 border border-purple-500/20">Laudo Anexado</span>
          </div>
        </div>

        <!-- Action Buttons (Bottom Row) -->
        <div class="flex flex-wrap gap-2 mt-4 pt-3 border-t border-white/5">
          <button @click="$emit('action', 'dados', candidato)" 
            class="px-3 py-1.5 rounded bg-white/5 hover:bg-white/10 text-xs font-medium text-white transition-colors">
            Dados
          </button>
          <button @click="$emit('action', 'documentos', candidato)" 
            class="px-3 py-1.5 rounded bg-white/5 hover:bg-white/10 text-xs font-medium text-white transition-colors">
            Documentos
          </button>
          <button @click="$emit('action', 'avaliar', candidato)" 
            class="px-3 py-1.5 rounded bg-white/5 hover:bg-white/10 text-xs font-medium text-white transition-colors">
            Avaliar
          </button>
          
          <div class="flex-grow"></div>

          <button @click="$emit('action', 'matricular', candidato)" 
            class="px-3 py-1.5 rounded bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 text-xs font-medium transition-colors">
            Matricular
          </button>
          <button @click="$emit('action', 'deletar', candidato)" 
            class="px-3 py-1.5 rounded bg-red-500/10 hover:bg-red-500/20 text-red-400 border border-red-500/30 text-xs font-medium transition-colors">
            Deletar
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
