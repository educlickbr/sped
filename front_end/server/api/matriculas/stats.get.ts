import { serverSupabaseClient } from '#supabase/server'

export default defineEventHandler(async (event) => {
    const query = getQuery(event)
    const client = await serverSupabaseClient(event)

    const { data, error } = await (client.rpc as any)('nxt_get_estudantes_matriculados_stats', {
        p_ano_semestre: query.ano_semestre,
        p_turno: query.turno || null,
        p_curso: query.curso || null,
        p_busca: query.busca || null,
        p_status: query.status || null,
        p_area: query.area || null,
        p_id_turma: query.id_turma || null
    })

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message
        })
    }

    return data
})
