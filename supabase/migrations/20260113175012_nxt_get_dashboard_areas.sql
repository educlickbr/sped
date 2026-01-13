CREATE OR REPLACE FUNCTION public.nxt_get_dashboard_areas(p_ano_semestre text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_result jsonb;
BEGIN

  --------------------------------------------------------------------
  -- 1. TURMAS DO ANO/SEMESTRE
  --------------------------------------------------------------------
  WITH turmas_filtradas AS (
    SELECT
      t.id AS id_turma,
      t.nome_curso,
      t.cod_turma,
      t.ano_semestre,
      c.area AS area_curso,   -- ENUM tipo_area
      c.id AS id_curso
    FROM turmas t
    JOIN curso c ON c.id = t.id_curso
    WHERE t.ano_semestre ILIKE p_ano_semestre
  ),

  --------------------------------------------------------------------
  -- 2. PROCESSOS AGRUPADOS POR TURMA
  --------------------------------------------------------------------
  processos_agg AS (
    SELECT
      tf.area_curso,
      tf.id_turma,
      COUNT(p.id) AS total_inscricoes
    FROM turmas_filtradas tf
    LEFT JOIN processos p ON p.turma_id = tf.id_turma
    GROUP BY tf.area_curso, tf.id_turma
  ),

  --------------------------------------------------------------------
  -- 3. TOTAL POR ÁREA
  --------------------------------------------------------------------
  areas_totais AS (
    SELECT
      area_curso,
      SUM(total_inscricoes) AS total_area
    FROM processos_agg
    GROUP BY area_curso
  ),

  --------------------------------------------------------------------
  -- 4. PERGUNTAS (area / turma)
  --------------------------------------------------------------------
  perguntas_area AS (
    SELECT
      p.id,
      p.pergunta AS label,
      p.tipo,
      p.opcoes,
      p.ordem,
      p.id_turma,
      p.area,        -- ENUM tipo_area
      p.escopo
    FROM perguntas_avaliacao_processos p
    WHERE COALESCE(p.ativo, true) IS TRUE
      AND p.escopo IN ('area','turma')
  ),

  --------------------------------------------------------------------
  -- 5. RESPOSTAS (sem filtro de turma ainda)
  --------------------------------------------------------------------
  respostas AS (
    SELECT
      r.id_pergunta_processo AS id_pergunta,
      r.id_user,
      r.resposta_texto AS valor
    FROM respostas_perguntas_avaliacao_processos r
  ),

  --------------------------------------------------------------------
  -- 6. AVALIAÇÃO POR TURMA (TOTALIZADORES)
  --------------------------------------------------------------------
  avaliacao_por_turma AS (
    SELECT
      tf.id_turma,

      -- perguntas válidas (numero + opção)
      COUNT(DISTINCT CASE 
        WHEN p.tipo IN ('numero','number','opcao','opção','radio','select')
        THEN p.id 
      END) AS total_perguntas,

      -- respostas somente dos alunos desta turma
      COUNT(
        CASE 
          WHEN pr.id IS NOT NULL AND r.valor IS NOT NULL 
          THEN 1 
        END
      ) AS total_respostas,

      CASE 
        WHEN COUNT(DISTINCT CASE 
               WHEN p.tipo IN ('numero','number','opcao','opção','radio','select') 
               THEN p.id END) = 0
          THEN 0
        ELSE ROUND(
          (
            COUNT(
              CASE WHEN pr.id IS NOT NULL AND r.valor IS NOT NULL THEN 1 END
            )::numeric * 100
          ) /
          COUNT(DISTINCT CASE 
            WHEN p.tipo IN ('numero','number','opcao','opção','radio','select') 
            THEN p.id END)
          , 1
        )
      END AS percentual_respostas

    FROM turmas_filtradas tf
    LEFT JOIN perguntas_area p
      ON (
           (p.escopo = 'area'  AND p.area     = tf.area_curso)  
        OR (p.escopo = 'turma' AND p.id_turma = tf.id_turma)
      )
    LEFT JOIN respostas r 
      ON r.id_pergunta = p.id
    LEFT JOIN processos pr
      ON pr.user_expandido_id = r.id_user
     AND pr.turma_id = tf.id_turma

    GROUP BY tf.id_turma
  ),

  --------------------------------------------------------------------
  -- 7. DETALHES DAS PERGUNTAS (apenas numero + opção)
  --------------------------------------------------------------------
  perguntas_detalhes AS (
    SELECT
      tf.id_turma,
      p.id AS id_pergunta,
      p.label,
      p.tipo,
      p.opcoes,
      p.ordem
    FROM turmas_filtradas tf
    JOIN perguntas_area p
      ON (
           (p.escopo = 'area'  AND p.area     = tf.area_curso)
        OR (p.escopo = 'turma' AND p.id_turma = tf.id_turma)
      )
    WHERE p.tipo IN ('numero','number','opcao','opção','radio','select')
  ),

  --------------------------------------------------------------------
  -- 8. ANALYTICS POR PERGUNTA (POR TURMA)
  --------------------------------------------------------------------
  perguntas_analytics AS (
    SELECT
      pd.id_turma,
      pd.id_pergunta,
      pd.label,
      pd.tipo,
      pd.ordem,

      CASE
        ----------------------------------------------------------------
        -- 📌 TIPO NUMÉRICO
        ----------------------------------------------------------------
        WHEN pd.tipo IN ('numero','number') THEN
          jsonb_build_object(
            'tipo', 'numero',
            'media',
              (
                SELECT AVG((r.resposta_texto)::numeric)
                FROM respostas_perguntas_avaliacao_processos r
                JOIN processos pr
                  ON pr.user_expandido_id = r.id_user
                 AND pr.turma_id = pd.id_turma
                WHERE r.id_pergunta_processo = pd.id_pergunta
              ),
            'total_respostas',
              (
                SELECT COUNT(*)
                FROM respostas_perguntas_avaliacao_processos r
                JOIN processos pr
                  ON pr.user_expandido_id = r.id_user
                 AND pr.turma_id = pd.id_turma
                WHERE r.id_pergunta_processo = pd.id_pergunta
              )
          )

        ----------------------------------------------------------------
        -- 📌 TIPO OPÇÃO
        ----------------------------------------------------------------
        ELSE
          jsonb_build_object(
            'tipo', 'opcao',
            'total_respostas',
              (
                SELECT COUNT(*)
                FROM respostas_perguntas_avaliacao_processos r
                JOIN processos pr
                  ON pr.user_expandido_id = r.id_user
                 AND pr.turma_id = pd.id_turma
                WHERE r.id_pergunta_processo = pd.id_pergunta
              ),
            'opcoes',
              (
                SELECT jsonb_agg(
                  jsonb_build_object(
                    'valor', opcao,
                    'qtd',
                      COALESCE((
                          SELECT COUNT(*) 
                          FROM respostas_perguntas_avaliacao_processos r
                          JOIN processos pr
                            ON pr.user_expandido_id = r.id_user
                           AND pr.turma_id = pd.id_turma
                          WHERE r.id_pergunta_processo = pd.id_pergunta
                            AND r.resposta_texto = opcao
                      ), 0)
                  )
                )
                FROM jsonb_array_elements_text(pd.opcoes) AS opcao
              )
          )
      END AS dados

    FROM perguntas_detalhes pd
  ),

  --------------------------------------------------------------------
  -- 9. AGRUPAMENTO FINAL POR TURMA
  --------------------------------------------------------------------
  turmas_final AS (
    SELECT
      tf.area_curso,
      jsonb_agg(
        jsonb_build_object(
          'id_turma', tf.id_turma,
          'nome_curso', tf.nome_curso,
          'cod_turma', tf.cod_turma,
          'total_inscricoes',
            (SELECT total_inscricoes FROM processos_agg pa WHERE pa.id_turma = tf.id_turma),

          'avaliacao',
            jsonb_build_object(
              'total_perguntas',
                (SELECT total_perguntas FROM avaliacao_por_turma av WHERE av.id_turma = tf.id_turma),
              'total_respostas',
                (SELECT total_respostas FROM avaliacao_por_turma av WHERE av.id_turma = tf.id_turma),
              'percentual_respostas',
                (SELECT percentual_respostas FROM avaliacao_por_turma av WHERE av.id_turma = tf.id_turma),
              'perguntas',
                (
                  SELECT jsonb_agg(
                    jsonb_build_object(
                      'id_pergunta', pd.id_pergunta,
                      'label', pd.label,
                      'tipo', pd.tipo,
                      'dados', pd.dados
                    )
                    ORDER BY pd.ordem
                  )
                  FROM perguntas_analytics pd
                  WHERE pd.id_turma = tf.id_turma
                )
            )
        )
        ORDER BY tf.nome_curso
      ) AS turmas
    FROM turmas_filtradas tf
    GROUP BY tf.area_curso
  )

  --------------------------------------------------------------------
  -- 10. RESULTADO FINAL (com área_normalized)
  --------------------------------------------------------------------
  SELECT jsonb_agg(
    jsonb_build_object(
      'area', a.area_curso,
      'area_normalized',
        CASE a.area_curso
          WHEN 'regulares'       THEN 'Regulares'
          WHEN 'extensao'        THEN 'Extensão'
          WHEN 'cursos_livres'   THEN 'Cursos Livres'
          WHEN 'eventos_editais' THEN 'Eventos / Editais'
          WHEN 'jornadas'        THEN 'Jornadas'
          ELSE INITCAP(REPLACE(a.area_curso::text, '_', ' '))
        END,
      'total_inscricoes', a.total_area,
      'turmas',
        (SELECT turmas FROM turmas_final t WHERE t.area_curso = a.area_curso)
    )
    ORDER BY a.area_curso
  )
  INTO v_result
  FROM areas_totais a;

  RETURN jsonb_build_object(
    'ano_semestre', p_ano_semestre,
    'areas', COALESCE(v_result, '[]'::jsonb)
  );

END;
$function$
