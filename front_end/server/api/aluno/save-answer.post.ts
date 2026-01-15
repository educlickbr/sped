import { getStudentContext } from '../../utils/student-context'

export default defineEventHandler(async (event) => {
    const { client, userExpandidoId } = await getStudentContext(event)
    const body = await readBody(event)
    
    // Validate Input
    if (!body.id_pergunta || !body.resposta) {
        throw createError({
            statusCode: 400,
            statusMessage: 'Faltando id_pergunta ou resposta'
        })
    }

    // Construct payload for nxt_salvar_respostas_usuario
    const answersPayload = [{
        id_pergunta: body.id_pergunta,
        resposta: String(body.resposta), // Ensure string
        nome_arquivo_original: ""
    }]

    // Use nxt_salvar_respostas_usuario which is proven to work in /inscricao
    // We pass user.id for p_id_usuario, and userExpandidoId for p_user_expandido_id regarding the context
    // Actually /inscricao passes p_id_usuario as auth ID and p_user_expandido_id as null.
    // But since we KNOW the expanded ID, we can try passing it if the function supports it, 
    // or just pass auth ID. Let's pass both to be robust, or follow /inscricao pattern if unsure.
    // /inscricao uses user.id || (user as any).sub.
    
    // We already have user object in getStudentContext?
    // getStudentContext returns { client, user (auth user), userExpandidoId ... }
    const { user } = await getStudentContext(event)
    const authUserId = user.id || (user as any).sub

    const { data, error } = await (client.rpc as any)('nxt_salvar_respostas_usuario', {
        p_id_usuario: authUserId,
        p_respostas: answersPayload,
        p_id_turma: body.id_turma || null,
        p_user_expandido_id: userExpandidoId // We pass this as we have it validated
    })

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message
        })
    }

    return { success: true, data }
})
