import { serverSupabaseClient } from '#supabase/server';

export default defineEventHandler(async (event) => {
    const body = await readBody(event);
    const client = await serverSupabaseClient(event);

    const { id_processo, status } = body;

    // Validate params
    if (!id_processo) {
        throw createError({
            statusCode: 400,
            statusMessage: 'id_processo is required'
        });
    }

    try {
        const { data, error } = await (client.rpc as any)('nxt_upsert_status_processo', {
            p_id_processo: id_processo,
            p_status: status // Can be null
        });

        if (error) throw error;

        if (!data.success) {
             throw createError({
                statusCode: 400,
                statusMessage: data.message
            });
        }

        return data;

    } catch (error: any) {
        console.error('Erro ao atualizar status do processo:', error);
        throw createError({
            statusCode: error.statusCode || 500,
            statusMessage: error.statusMessage || error.message || 'Erro interno ao atualizar status.'
        });
    }
});
