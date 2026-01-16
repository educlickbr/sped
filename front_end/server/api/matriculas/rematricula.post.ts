import { serverSupabaseClient } from '#supabase/server';

export default defineEventHandler(async (event) => {
    const body = await readBody(event);
    const client = await serverSupabaseClient(event);

    const { id_user_expandido, id_turma_atual } = body;

    // Validate params
    if (!id_user_expandido || !id_turma_atual) {
        throw createError({
            statusCode: 400,
            statusMessage: 'id_user_expandido and id_turma_atual are required'
        });
    }

    try {
        const { data, error } = await (client.rpc as any)('nxt_upsert_rematricula', {
            p_id_user_expandido: id_user_expandido,
            p_id_turma_atual: id_turma_atual
        });

        if (error) throw error;

        // The RPC returns a JSON object with success/message
        if (!data.success) {
             throw createError({
                statusCode: 400,
                statusMessage: data.message
            });
        }

        return data;

    } catch (error: any) {
        console.error('Erro na rematrícula:', error);
        throw createError({
            statusCode: error.statusCode || 500,
            statusMessage: error.statusMessage || error.message || 'Erro interno ao realizar rematrícula.'
        });
    }
});
