import { serverSupabaseClient } from '#supabase/server'

export default defineEventHandler(async (event) => {
  const client = await serverSupabaseClient(event)
  const query = getQuery(event)

  const {
    area,
    anoSemestre,
    dataInicio
  } = query

  try {
    const { data, error } = await (client.rpc as any)('nxt_get_listas_candidatos', {
      p_area: area,
      p_ano_semestre: anoSemestre,
      p_status_processo: null,
      p_tipo_processo: 'seletivo',
      p_tipo_candidatura: 'estudante',
      p_filtros: [{ id_pergunta: "518e1943-1a84-4017-b283-67b3914e46e2", resposta: "Inscrição Deferida" }],
      p_data_inscricao_inicio: dataInicio ? new Date(String(dataInicio).includes('T') ? String(dataInicio) : String(dataInicio) + 'T00:00:00').toISOString() : null
    })

    if (error) {
      throw createError({
        statusCode: 500,
        statusMessage: error.message,
      })
    }

    return data
  } catch (err: any) {
     throw createError({
        statusCode: 500,
        statusMessage: err.message, 
     })
  }
})
