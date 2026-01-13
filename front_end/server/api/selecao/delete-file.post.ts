import { serverSupabaseClient, serverSupabaseUser } from "#supabase/server";

export default defineEventHandler(async (event) => {
    // 1. Auth Check (Admin)
    const user = await serverSupabaseUser(event);
    if (!user) {
        throw createError({
            statusCode: 401,
            statusMessage: "Unauthorized",
        });
    }

    // 2. Read Body
    const body = await readBody(event);
    const { fileName, id_pergunta, targetUserId } = body;

    if (!fileName || !id_pergunta || !targetUserId) {
        throw createError({
            statusCode: 400,
            statusMessage: "Missing fileName, id_pergunta or targetUserId",
        });
    }

    const client = await serverSupabaseClient(event);

    const results = {
        edge: { success: false, error: null as any },
        db: { success: false, error: null as any },
    };

    // 3. Call Edge Function (deletar_arquivos) via Supabase Client
    try {
        const { error: functionError } = await client.functions.invoke(
            "deletar_arquivos",
            {
                body: {
                    fileName,
                    pasta: "usr",
                },
            },
        );

        if (functionError) {
            console.warn("Edge Function Delete Warning:", functionError);
            results.edge.error = functionError;
        } else {
            results.edge.success = true;
        }
    } catch (err) {
        console.warn("Edge Function Delete Exception:", err);
        results.edge.error = err;
    }

    // 4. Update DB (operar_resposta_arquivo)
    try {
        const { error: dbError } = await (client as any).rpc(
            "operar_resposta_arquivo",
            {
                p_id_user_expandido: targetUserId,
                p_id_pergunta: id_pergunta,
                p_operacao: "deletar",
            },
        );

        if (dbError) {
            console.warn("DB Delete Warning:", dbError);
            results.db.error = dbError;
        } else {
            results.db.success = true;
        }
    } catch (err) {
        console.warn("DB Delete Exception:", err);
        results.db.error = err;
    }

    // 5. Evaluate Results
    if (!results.edge.success && !results.db.success) {
        const combinedError = {
            edge: results.edge.error,
            db: results.db.error,
        };
        throw createError({
            statusCode: 502,
            statusMessage: `Delete Completely Failed: ${JSON.stringify(combinedError)}`,
        });
    }

    return {
        success: true,
        details: results,
        message: "File deletion processed.",
    };
});
