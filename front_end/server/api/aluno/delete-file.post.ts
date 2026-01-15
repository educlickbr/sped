import { getStudentContext } from '../../utils/student-context'

export default defineEventHandler(async (event) => {
    // 1. Auth Check (Student)
    const { client, userExpandidoId } = await getStudentContext(event)

    // 2. Read Body
    const body = await readBody(event)
    const { fileName, id_pergunta } = body

    if (!fileName || !id_pergunta) {
        throw createError({
            statusCode: 400,
            statusMessage: "Missing fileName or id_pergunta",
        })
    }

    const results = {
        edge: { success: false, error: null as any },
        db: { success: false, error: null as any },
    }

    // 3. Call Edge Function (deletar_arquivos) via Supabase Client
    // Does Edge Function need special permissions? Usually it sends the request.
    // If it relies on sending user context, we are doing it via the client which is authenticated as the user (because we got it via serverSupabaseClient(event)).
    // Wait, getStudentContext calls serverSupabaseClient(event).
    // Standard Supabase client forwards the JWT.
    try {
        const { error: functionError } = await client.functions.invoke(
            "deletar_arquivos",
            {
                body: {
                    fileName,
                    pasta: "usr",
                },
            },
        )

        if (functionError) {
            console.warn("Edge Function Delete Warning:", functionError)
            results.edge.error = functionError
        } else {
            results.edge.success = true
        }
    } catch (err) {
        console.warn("Edge Function Delete Exception:", err)
        results.edge.error = err
    }

    // 4. Update DB (operar_resposta_arquivo)
    try {
        const { error: dbError } = await (client as any).rpc(
            "operar_resposta_arquivo",
            {
                p_id_user_expandido: userExpandidoId, // Forced from session
                p_id_pergunta: id_pergunta,
                p_operacao: "deletar",
            },
        )

        if (dbError) {
            console.warn("DB Delete Warning:", dbError)
            results.db.error = dbError
        } else {
            results.db.success = true
        }
    } catch (err) {
        console.warn("DB Delete Exception:", err)
        results.db.error = err
    }

    // 5. Evaluate Results
    if (!results.edge.success && !results.db.success) {
        const combinedError = {
            edge: results.edge.error,
            db: results.db.error,
        }
        throw createError({
            statusCode: 502,
            statusMessage: `Delete Completely Failed: ${JSON.stringify(combinedError)}`,
        })
    }

    return {
        success: true,
        details: results,
        message: "File deletion processed.",
    }
})
