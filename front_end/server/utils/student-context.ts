import { serverSupabaseClient, serverSupabaseUser } from '#supabase/server'

export async function getStudentContext(event: any) {
    const user = await serverSupabaseUser(event)
    if (!user) {
        throw createError({ statusCode: 401, statusMessage: 'Unauthorized' })
    }

    const client = await serverSupabaseClient(event)
    const userId = user.id || (user as any).sub

    // Fetch user_expandido_id
    // We use a direct query to avoid RPC signature/cache issues. 
    // We strictly need the ID for the next queries.
    const { data, error } = await client
        .from('user_expandido')
        .select('id, nome, sobrenome, email, imagem_user')
        .eq('user_id', userId)
        .single()

    if (error) {
        console.error('Error fetching student context (Direct):', error)
        throw createError({ statusCode: 500, statusMessage: `Error fetching profile: ${error.message}` })
    }

    if (!data) {
        console.error('Student context data is null for user:', userId)
        throw createError({ statusCode: 403, statusMessage: 'Profile not found (No Data)' })
    }
    
    // Map to expected format (RPC returned 'user_expandido_id', table has 'id')
    const rawData = data as any
    const profile = {
        ...rawData,
        user_expandido_id: rawData.id
    }

    // If profile exists but user_expandido_id is null, it means usage of loose auth or sync issue
    if (!profile.user_expandido_id) {
         console.warn('Student context found but user_expandido_id is null:', profile)
         // We might decide to throw here or let it pass (queries will return empty). 
         // But for "Meus Processos", we need a valid ID.
         throw createError({ statusCode: 403, statusMessage: 'Profile incomplete (No ID)' })
    }


    return {
        user,
        client,
        userExpandidoId: profile.user_expandido_id,
        profile
    }
}
