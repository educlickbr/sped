import { getStudentContext } from '../../utils/student-context'

export default defineEventHandler(async (event) => {
    const { client, userExpandidoId } = await getStudentContext(event)
    const query = getQuery(event)

    // Validate required params
    if (!query.tipo_processo || !query.area) { // candidatura and turma can sometimes be implicit/null depending on context, but let's assume strictness if provided?
        // nxt_get_respostas_arquivos_area allows implicit if needed, but let's check
    }

    const { data, error } = await (client.rpc as any)('nxt_get_respostas_arquivos_area', {
        p_tipo_processo: query.tipo_processo,
        p_area: query.area,
        p_tipo_candidatura: query.tipo_candidatura || null,
        p_id_user_expandido: userExpandidoId,
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
