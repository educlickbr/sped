<script setup lang="ts">
const props = defineProps<{
    candidatos: any[];
    totalCount: number;
}>();

// Compute statistics from candidates
const stats = computed(() => {
    const all = props.candidatos;
    
    // PCD Stats
    const pcdCount = all.filter(c => c.pcd === 'Sim').length;
    const pcdPercentage = all.length > 0 ? Math.round((pcdCount / all.length) * 100) : 0;
    
    // Gender distribution
    const genderCounts = all.reduce((acc, c) => {
        const g = c.genero || 'Não informado';
        acc[g] = (acc[g] || 0) + 1;
        return acc;
    }, {} as Record<string, number>);
    
    const genderData = Object.entries(genderCounts)
        .map(([name, count]) => ({ name, count: count as number, percentage: Math.round(((count as number) / all.length) * 100) }))
        .sort((a, b) => b.count - a.count);
    
    // Race distribution
    const raceCounts = all.reduce((acc, c) => {
        const r = c.raca || 'Não informado';
        acc[r] = (acc[r] || 0) + 1;
        return acc;
    }, {} as Record<string, number>);
    
    const raceData = Object.entries(raceCounts)
        .map(([name, count]) => ({ name, count: count as number, percentage: Math.round(((count as number) / all.length) * 100) }))
        .sort((a, b) => b.count - a.count);
    
    // Income distribution
    const incomeCounts = all.reduce((acc, c) => {
        const i = c.renda || 'Não informado';
        acc[i] = (acc[i] || 0) + 1;
        return acc;
    }, {} as Record<string, number>);
    
    const incomeData = Object.entries(incomeCounts)
        .map(([name, count]) => ({ name, count: count as number, percentage: Math.round(((count as number) / all.length) * 100) }))
        .sort((a, b) => b.count - a.count);
    
    return {
        pcdCount,
        pcdPercentage,
        genderData,
        raceData,
        incomeData
    };
});
</script>

<template>
    <div class="space-y-4">
        <!-- Stats Cards -->
        <div class="grid grid-cols-2 gap-3">
            <!-- Total -->
            <div class="bg-[#16161E] border border-white/10 rounded-lg p-3">
                <div class="text-[10px] text-secondary-600 uppercase tracking-wide mb-1">Total</div>
                <div class="text-2xl font-bold text-white">{{ totalCount }}</div>
                <div class="text-[10px] text-gray-500 mt-0.5">candidatos</div>
            </div>
            
            <!-- PCD -->
            <div class="bg-[#16161E] border border-white/10 rounded-lg p-3">
                <div class="text-[10px] text-secondary-600 uppercase tracking-wide mb-1">PCD</div>
                <div class="text-2xl font-bold text-blue-400">{{ stats.pcdPercentage }}%</div>
                <div class="text-[10px] text-gray-500 mt-0.5">{{ stats.pcdCount }} pessoas</div>
            </div>
        </div>

        <!-- Gender Distribution -->
        <div class="bg-[#16161E] border border-white/10 rounded-lg p-3">
            <div class="text-xs font-semibold text-white mb-3">Identidade de Gênero</div>
            <div class="space-y-2">
                <div v-for="item in stats.genderData" :key="item.name" class="space-y-1">
                    <div class="flex justify-between text-[10px]">
                        <span class="text-gray-400 truncate">{{ item.name }}</span>
                        <span class="text-white font-medium">{{ item.count }}</span>
                    </div>
                    <div class="h-1.5 bg-white/5 rounded-full overflow-hidden">
                        <div 
                            class="h-full bg-gradient-to-r from-primary to-primary/60 rounded-full transition-all"
                            :style="{ width: item.percentage + '%' }"
                        ></div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Race Distribution -->
        <div class="bg-[#16161E] border border-white/10 rounded-lg p-3">
            <div class="text-xs font-semibold text-white mb-3">Raça/Cor</div>
            <div class="space-y-2">
                <div v-for="item in stats.raceData" :key="item.name" class="space-y-1">
                    <div class="flex justify-between text-[10px]">
                        <span class="text-gray-400 truncate">{{ item.name }}</span>
                        <span class="text-white font-medium">{{ item.count }}</span>
                    </div>
                    <div class="h-1.5 bg-white/5 rounded-full overflow-hidden">
                        <div 
                            class="h-full bg-gradient-to-r from-purple-500 to-purple-400 rounded-full transition-all"
                            :style="{ width: item.percentage + '%' }"
                        ></div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Income Distribution -->
        <div class="bg-[#16161E] border border-white/10 rounded-lg p-3">
            <div class="text-xs font-semibold text-white mb-3">Renda Familiar</div>
            <div class="space-y-2">
                <div v-for="item in stats.incomeData" :key="item.name" class="space-y-1">
                    <div class="flex justify-between text-[10px]">
                        <span class="text-gray-400 truncate text-[9px]">{{ item.name }}</span>
                        <span class="text-white font-medium">{{ item.count }}</span>
                    </div>
                    <div class="h-1.5 bg-white/5 rounded-full overflow-hidden">
                        <div 
                            class="h-full bg-gradient-to-r from-emerald-500 to-emerald-400 rounded-full transition-all"
                            :style="{ width: item.percentage + '%' }"
                        ></div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>
