import { serverSupabaseClient } from '#supabase/server';

export default defineEventHandler(async (event) => {
    const body = await readBody(event);
    const client = await serverSupabaseClient(event);

    const { id_matricula, status } = body;

    if (!id_matricula || !status) {
        throw createError({
            statusCode: 400,
            statusMessage: 'id_matricula and status are required'
        });
    }

    const { data, error } = await (client.rpc as any)('nxt_upsert_status_matricula', {
        p_id_matricula: id_matricula,
        p_status: status
    });

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message
        });
    }

    return data;
});
