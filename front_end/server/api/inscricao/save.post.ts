import { serverSupabaseClient, serverSupabaseUser } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const user = await serverSupabaseUser(event);
    if (!user) {
        throw createError({
            statusCode: 401,
            statusMessage: "Unauthorized",
        });
    }

    const body = await readBody(event);
    const { p_id_turma, p_id_pergunta, p_resposta, p_respostas_batch } = body;

    // Validation: Require either single question or batch
    if (
        !p_id_pergunta &&
        (!p_respostas_batch || !Array.isArray(p_respostas_batch))
    ) {
        throw createError({
            statusCode: 400,
            statusMessage: "Question ID or Batch Answers required",
        });
    }

    const client = await serverSupabaseClient(event);
    const userId = user.id || (user as any).sub;

    console.log("Save Attempt:", {
        userId: userId,
        pergunta: p_id_pergunta || "BATCH",
        turma: p_id_turma,
        batchSize: p_respostas_batch?.length || 1,
    });

    try {
        let p_respostas: any[] = [];

        if (p_respostas_batch && Array.isArray(p_respostas_batch)) {
            p_respostas = p_respostas_batch;
        } else {
            p_respostas = [
                {
                    id_pergunta: p_id_pergunta,
                    resposta: String(p_resposta),
                    nome_arquivo_original: "",
                },
            ];
        }

        // Using any cast to bypass lint issues and match the new signature
        const { data, error } = await (client as any).rpc(
            "nxt_salvar_respostas_usuario",
            {
                p_id_usuario: userId,
                p_respostas: p_respostas,
                p_id_turma: p_id_turma,
                p_user_expandido_id: null, // Explicitly null to match signature
            },
        );

        if (error) {
            console.error("RPC Error:", error);
            throw error;
        }

        return { success: true, data };
    } catch (err: any) {
        console.error("BFF Save Error Detail:", err);
        throw createError({
            statusCode: 500,
            statusMessage: "Erro ao salvar resposta",
            data: err.message || err,
        });
    }
});
