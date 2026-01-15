import { serverSupabaseClient } from '#supabase/server'

export default defineEventHandler(async (event) => {
  const client = await serverSupabaseClient(event)
  const body = await readBody(event)

  const {
    id_curso,
    pergunta_1,
    pergunta_2,
    pergunta_3,
    rodape
  } = body

  try {
    // @ts-ignore
    const { error } = await client.rpc('nxt_upsert_ficha_avaliacao', {
      p_id_curso: id_curso,
      p_pergunta_1: pergunta_1,
      p_pergunta_2: pergunta_2,
      p_pergunta_3: pergunta_3,
      p_rodape: rodape
    })

    if (error) {
      throw createError({
        statusCode: 500,
        statusMessage: error.message,
      })
    }

    return { success: true }
  } catch (err: any) {
     throw createError({
        statusCode: 500,
        statusMessage: err.message, 
     })
  }
})
