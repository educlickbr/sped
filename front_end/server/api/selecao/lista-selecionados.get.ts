import { serverSupabaseClient } from '#supabase/server'

export default defineEventHandler(async (event) => {
  const client = await serverSupabaseClient(event)
  const query = getQuery(event)

  const {
    area,
    anoSemestre,
    tipoCandidatura,
    tipoProcesso
  } = query

  try {
    const { data, error } = await (client.rpc as any)('nxt_get_lista_selecionados', {
      p_area: area,
      p_ano_semestre: anoSemestre,
      p_status_processo: 'Aprovado',
      p_tipo_processo: tipoProcesso || 'seletivo',
      p_tipo_candidatura: tipoCandidatura || 'estudante'
    })

    if (error) {
        console.error('RPC Error:', error)
      throw createError({
        statusCode: 500,
        statusMessage: error.message,
      })
    }

    return data
  } catch (err: any) {
     console.error('Handler Error:', err)
     throw createError({
        statusCode: 500,
        statusMessage: err.message, 
     })
  }
})
