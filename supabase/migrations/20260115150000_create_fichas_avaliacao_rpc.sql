CREATE OR REPLACE FUNCTION public.nxt_get_fichas_avaliacao_candidatos(
    p_area tipo_area, 
    p_ano_semestre text, 
    p_filtros jsonb DEFAULT '[]'::jsonb, 
    p_tipo_processo tipo_processo DEFAULT NULL::tipo_processo, 
    p_tipo_candidatura tipo_candidatura DEFAULT NULL::tipo_candidatura, 
    p_status_processo text DEFAULT NULL::text,
    p_data_inscricao_inicio timestamp with time zone DEFAULT NULL::timestamp with time zone
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_result jsonb;
BEGIN
    WITH

    --------------------------------------------------------------------
    -- TURMAS (Joined with Ficha Avaliação)
    --------------------------------------------------------------------
    turmas_filtradas AS (
        SELECT
            t.id AS turma_id,
            t.nome_curso AS nome_turma,
            t.turno,
            t.ano_semestre,
            c.id AS curso_id,
            c.nome_curso AS nome_curso_oficial,
            c.area,
            -- Fields from curso_ficha_avaliacao
            cfa.pergunta_1,
            cfa.pergunta_2,
            cfa.pergunta_3,
            cfa.rodape
        FROM turmas t
        JOIN curso c ON c.id = t.id_curso
        LEFT JOIN curso_ficha_avaliacao cfa ON cfa.id_curso = c.id
        WHERE c.area = p_area
          AND t.ano_semestre = p_ano_semestre
    ),

    --------------------------------------------------------------------
    -- RESPOSTAS BÁSICAS
    --------------------------------------------------------------------
    respostas_basicas AS (
        SELECT
            r.user_expandido_id,

            MAX(CASE WHEN r.id_pergunta = '29a21c21-b102-434e-a05b-08cc5e871de7'
                     THEN r.resposta END) AS rg,

            MAX(CASE WHEN r.id_pergunta = '20467206-19d9-4bb9-8a54-e6625f101282'
                     THEN r.resposta END) AS cpf,

            MAX(CASE WHEN r.id_pergunta = '32b1a387-a2a9-4f79-af30-d32026af64fe'
                     THEN r.resposta END) AS nome_social,
            
            MAX(CASE WHEN r.id_pergunta = '25edf1cb-ed2f-4ae2-a85d-ef5c6f0af8ea'
                     THEN r.resposta END) AS identidade_genero

        FROM respostas r
        GROUP BY r.user_expandido_id
    ),

    --------------------------------------------------------------------
    -- CANDIDATOS BASE
    --------------------------------------------------------------------
    candidatos_base AS (
        SELECT
            tf.turma_id,
            pr.id AS processo_id,
            ux.id AS user_expandido_id,

            TRIM(COALESCE(ux.nome,'') || ' ' || COALESCE(ux.sobrenome,'')) AS nome_registro,
            
            rb.nome_social,
            rb.identidade_genero,
            rb.rg,
            rb.cpf,

            pr.tipo_candidatura,

            ROW_NUMBER() OVER (
                PARTITION BY tf.turma_id
                ORDER BY pr.created_at ASC, pr.id ASC
            ) AS num_classificacao

        FROM turmas_filtradas tf
        JOIN processos pr
          ON pr.turma_id = tf.turma_id

        JOIN user_expandido ux
          ON ux.id = pr.user_expandido_id

        LEFT JOIN respostas_basicas rb
          ON rb.user_expandido_id = ux.id

        LEFT JOIN respostas_perguntas_avaliacao_processos resp_def
          ON resp_def.id_user = ux.id
         AND resp_def.id_processo = pr.id
         AND resp_def.id_pergunta_processo = '518e1943-1a84-4017-b283-67b3914e46e2'
         AND resp_def.resposta_texto = 'Inscrição Deferida'

        WHERE resp_def.id_user IS NOT NULL
          AND (p_tipo_candidatura IS NULL OR pr.tipo_candidatura = p_tipo_candidatura)
          AND (p_tipo_processo IS NULL OR pr.tipo_processo = p_tipo_processo)
          AND (p_status_processo IS NULL OR pr.status = p_status_processo)
          AND (p_data_inscricao_inicio IS NULL OR pr.created_at >= p_data_inscricao_inicio)
    ),

    --------------------------------------------------------------------
    -- NOME FINAL
    --------------------------------------------------------------------
    candidatos_nome AS (
        SELECT
            cb.*,
            CASE 
                WHEN cb.identidade_genero IN 
                     ('Mulher Trans','Homem Trans','Travesti','Não Binário')
                     AND cb.nome_social IS NOT NULL AND cb.nome_social <> ''
                THEN cb.nome_social
                ELSE cb.nome_registro
            END AS nome_final
        FROM candidatos_base cb
    ) 

    --------------------------------------------------------------------
    -- JSON FINAL
    --------------------------------------------------------------------
    SELECT jsonb_agg(
        jsonb_build_object(
            'id_turma', tf.turma_id,
            'nome_turma', tf.nome_turma,
            'turno', tf.turno,
            
            -- Returned Params for Ficha Avaliação
            'pergunta_1', tf.pergunta_1,
            'pergunta_2', tf.pergunta_2,
            'pergunta_3', tf.pergunta_3,
            'rodape', tf.rodape,
            
            'alunos', (
                SELECT COALESCE(
                    jsonb_agg(
                        jsonb_build_object(
                            'id_processo', cn.processo_id,
                            'id_user_expandido', cn.user_expandido_id,
                            'nome', cn.nome_final,
                            'rg', cn.rg,
                            'cpf', cn.cpf
                        )
                        ORDER BY cn.nome_final
                    ),
                    '[]'::jsonb
                )
                FROM candidatos_nome cn
                WHERE cn.turma_id = tf.turma_id
            )
        )
        ORDER BY tf.nome_turma ASC
    )
    INTO v_result
    FROM turmas_filtradas tf;

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$function$;
