import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const query = getQuery(event);
    const client = await serverSupabaseClient(event);

    // Default to 'estudante' if not provided
    const tipoCandidatura = query.tipo_candidatura || "estudante";

    // Current timestamp for filtering
    const now = new Date().toISOString();

    try {
        let resultData = [];

        if (tipoCandidatura === "docente") {
            const { data, error } = await (client as any).rpc(
                "listar_turmas_disponiveis_docente",
                { p_data: now, p_area: null, p_ano_semestre: null },
            );
            if (error) throw error;
            resultData = data || [];
        } else {
            const { data, error } = await (client as any).rpc(
                "listar_turmas_disponiveis_v2",
                { p_data: now, p_area: null, p_ano_semestre: null },
            );
            if (error) throw error;
            resultData = data || [];
        }

        // Return raw data, frontend will handle filtering/display
        return {
            items: resultData,
            source: tipoCandidatura,
        };
    } catch (err: any) {
        throw createError({
            statusCode: 500,
            statusMessage: "Erro ao buscar cursos disponíveis.",
            data: err.message,
        });
    }
});
