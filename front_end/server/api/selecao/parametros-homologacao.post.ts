import { serverSupabaseClient } from '#supabase/server'

export default defineEventHandler(async (event) => {
  const client = await serverSupabaseClient(event)
  const body = await readBody(event)

  const {
    id_turma,
    data_prova,
    hora_redacao,
    hora_prova_pratica,
    texto_cabecalho_curso
  } = body

  try {
    const { error } = await (client.rpc as any)('nxt_upsert_parametros_homologacao', {
      p_id_turma: id_turma,
      p_data_prova: data_prova,
      p_hora_redacao: hora_redacao,
      p_hora_prova_pratica: hora_prova_pratica,
      p_texto_cabecalho_curso: texto_cabecalho_curso
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
