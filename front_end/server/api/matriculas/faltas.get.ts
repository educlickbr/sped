import { serverSupabaseClient } from '#supabase/server';

export default defineEventHandler(async (event) => {
    const query = getQuery(event);
    const client = await serverSupabaseClient(event);

    if (!query.id_aluno || !query.id_turma) {
        throw createError({
            statusCode: 400,
            statusMessage: 'id_aluno and id_turma are required'
        });
    }

    const { data, error } = await (client.rpc as any)('nxt_get_faltas_aluno_turma', {
        p_id_aluno: query.id_aluno,
        p_id_turma: query.id_turma
    });

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message
        });
    }

    return data;
});
