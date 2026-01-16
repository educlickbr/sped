import { serverSupabaseClient } from '#supabase/server';

export default defineEventHandler(async (event) => {
    const query = getQuery(event);
    const client = await serverSupabaseClient(event);

    const { area, tipo_candidatura, tipo_processo, user_id, id_turma } = query;

    // Validate required params
    if (!area || !tipo_candidatura || !tipo_processo || !user_id) {
        throw createError({
            statusCode: 400,
            statusMessage: 'Parâmetros obrigatórios ausentes: area, tipo_candidatura, tipo_processo, user_id'
        });
    }

    try {
        const { data, error } = await (client as any).rpc('nxt_get_respostas_arquivos_area', {
            p_area: String(area),
            p_tipo_candidatura: String(tipo_candidatura),
            p_tipo_processo: String(tipo_processo),
            p_id_user_expandido: String(user_id),
            p_id_turma: id_turma ? String(id_turma) : null
        });

        if (error) throw error;
        
        return { success: true, documentos: data };

    } catch (error: any) {
        console.error('Erro ao buscar documentos:', error);
        throw createError({
            statusCode: 500,
            statusMessage: 'Erro interno ao buscar documentos.',
            data: error.message
        });
    }
});
