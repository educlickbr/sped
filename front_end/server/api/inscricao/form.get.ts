import { serverSupabaseClient, serverSupabaseUser } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const user = await serverSupabaseUser(event);
    if (!user) {
        throw createError({
            statusCode: 401,
            statusMessage: "Unauthorized",
        });
    }

    const { id: turmaId, tipo, processo } = getQuery(event);

    if (!turmaId) {
        throw createError({
            statusCode: 400,
            statusMessage: "Missing turma id",
        });
    }

    const client = await serverSupabaseClient(event);
    const authId = user.id || (user as any).sub;

    try {
        // 1. Get user_expandido_id first
        const { data: profileData, error: profileError } =
            await (client.rpc as any)(
                "get_user_expandido",
                { p_auth_id: authId },
            );

        if (profileError || !profileData?.user_expandido_id) {
            throw createError({
                statusCode: 404,
                statusMessage: "User profile not found",
            });
        }

        const userExpandidoId = profileData.user_expandido_id;

        // 2. Call the main form function
        const { data: formData, error: formError } = await (client.rpc as any)(
            "nxt_get_respostas_usuario_turma",
            {
                p_user_id: userExpandidoId,
                p_turma_id: turmaId,
                p_tipo_processo: processo || null,
                p_tipo_candidatura: tipo || null,
            },
        );

        if (formError) {
            console.error("RPC Error in /api/inscricao/form:", formError);
            throw createError({
                statusCode: 500,
                statusMessage: "Database function error",
                data: formError,
            });
        }

        return formData;
    } catch (err: any) {
        console.error("General error in /api/inscricao/form:", err);
        throw createError({
            statusCode: err.statusCode || 500,
            statusMessage: err.statusMessage || "Internal Server Error",
        });
    }
});
