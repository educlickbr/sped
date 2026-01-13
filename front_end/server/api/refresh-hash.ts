import { serverSupabaseClient, serverSupabaseUser } from "#supabase/server";

/**
 * Endpoint otimizado para renovar APENAS a hash do Bunny.net
 * Não busca perfil ou outros dados - apenas chama hash_app
 * Útil para quando a hash expira (5 min) mas o usuário ainda está ativo
 */
export default defineEventHandler(async (event) => {
    const user = await serverSupabaseUser(event);

    if (!user) {
        return { 
            hash_base: null,
            error: 'User not authenticated' 
        };
    }

    const client = await serverSupabaseClient(event);
    const userId = user.id || (user as any).sub;

    try {
        // 🎯 Chamada única e leve - só a Edge Function
        const { data: hashData, error: hashError } = await client.functions.invoke("hash_app", {
            body: {
                user_id: userId,
                path: "/usr/",
            },
        });

        if (hashError) {
            console.error("Hash generation error:", hashError);
            return { 
                hash_base: null, 
                error: hashError.message 
            };
        }

        return {
            hash_base: hashData?.url || null,
            refreshed_at: new Date().toISOString()
        };
    } catch (err) {
        console.error("Error in /api/refresh-hash:", err);
        return {
            hash_base: null,
            error: (err as any).message
        };
    }
});
