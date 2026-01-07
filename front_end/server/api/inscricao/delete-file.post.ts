import { serverSupabaseClient, serverSupabaseUser } from "#supabase/server";

export default defineEventHandler(async (event) => {
    // 1. Auth Check
    const user = await serverSupabaseUser(event);
    if (!user) {
        throw createError({
            statusCode: 401,
            statusMessage: "Unauthorized",
        });
    }

    // 2. Read Body
    const body = await readBody(event);
    const { fileName, id_pergunta } = body;

    if (!fileName || !id_pergunta) {
        throw createError({
            statusCode: 400,
            statusMessage: "Missing fileName or id_pergunta",
        });
    }

    const client = await serverSupabaseClient(event);
    const userId = user.id || (user as any).sub;

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
        // Fetch expanded user ID using RPC
        const { data: profileData, error: rpcError } =
            await (client.rpc as any)(
                "get_user_expandido",
                {
                    p_auth_id: userId,
                },
            );

        if (rpcError || !profileData) {
            throw new Error(
                rpcError?.message || "Profile not found for DB delete",
            );
        }

        const userExpandidoId = (profileData as any).user_expandido_id ||
            (profileData as any).id;

        if (!userExpandidoId) {
            throw new Error("Profile ID not found in response");
        }

        const { error: dbError } = await (client as any).rpc(
            "operar_resposta_arquivo",
            {
                p_id_user_expandido: userExpandidoId,
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
    // If BOTH failed, throw error.
    if (!results.edge.success && !results.db.success) {
        const combinedError = {
            edge: results.edge.error,
            db: results.db.error,
        };
        throw createError({
            statusCode: 502,
            statusMessage: `Delete Completely Failed: ${
                JSON.stringify(combinedError)
            }`,
        });
    }

    // If at least one succeeded, return success with details
    return {
        success: true,
        details: results,
        message:
            "File deletion processed. (Partial success if one system failed)",
    };
});
