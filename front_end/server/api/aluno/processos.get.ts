import { getStudentContext } from '../../utils/student-context'

export default defineEventHandler(async (event) => {
    const { client, userExpandidoId } = await getStudentContext(event)

    const { data, error } = await (client.rpc as any)('nxt_get_turmas_por_aluno_processos', {
        p_id_user_expandido: userExpandidoId
    })

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message
        })
    }

    return data
})
