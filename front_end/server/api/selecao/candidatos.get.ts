import { serverSupabaseClient } from '#supabase/server';

export default defineEventHandler(async (event) => {
    const query = getQuery(event);
    const client = await serverSupabaseClient(event);

    const { 
        id_turma, 
        pagina, 
        limite, 
        tipo_candidatura, 
        busca, 
        filtros, 
        pcd, 
        laudo, 
        ordenar_por, 
        ordenar_como 
    } = query;

    try {
        const { data, error } = await (client.rpc as any)('nxt_get_candidatos_processo_turma_v3', {
            p_id_turma: id_turma || null,
            p_pagina: pagina ? parseInt(String(pagina)) : 1,
            p_limite: limite ? parseInt(String(limite)) : 20,
            p_tipo_candidatura: tipo_candidatura || null,
            p_busca: busca || null,
            p_filtros: filtros ? JSON.parse(String(filtros)) : [],
            p_pcd: pcd || null,
            p_laudo: laudo === 'true' ? true : (laudo === 'false' ? false : null),
            p_ordenar_por: ordenar_por || 'nome_completo',
            p_ordenar_como: ordenar_como || 'ASC'
        });

        if (error) throw error;

        return data;

    } catch (error: any) {
        console.error('Erro ao buscar candidatos:', error);
        throw createError({
            statusCode: error.statusCode || 500,
            statusMessage: error.statusMessage || error.message || 'Erro interno ao buscar candidatos.'
        });
    }
});
