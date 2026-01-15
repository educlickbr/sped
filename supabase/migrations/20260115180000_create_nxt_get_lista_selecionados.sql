CREATE OR REPLACE FUNCTION public.nxt_get_lista_selecionados(
    p_area tipo_area, 
    p_ano_semestre text, 
    p_tipo_processo tipo_processo DEFAULT NULL::tipo_processo, 
    p_tipo_candidatura tipo_candidatura DEFAULT NULL::tipo_candidatura, 
    p_status_processo text DEFAULT 'Aprovado'::text
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
    -- TURMAS
    --------------------------------------------------------------------
    turmas_filtradas AS (
        SELECT
            t.id AS turma_id,
            t.nome_curso AS nome_turma,
            t.turno,
            t.ano_semestre,
            c.id AS curso_id,
            c.nome_curso AS nome_curso_oficial,
            c.area
        FROM turmas t
        JOIN curso c ON c.id = t.id_curso
        WHERE c.area = p_area
          AND t.ano_semestre = p_ano_semestre
    ),

    --------------------------------------------------------------------
    -- RESPOSTAS BÁSICAS (Necessário para resolução do Nome Social)
    --------------------------------------------------------------------
    respostas_basicas AS (
        SELECT
            r.user_expandido_id,
            MAX(CASE WHEN r.id_pergunta = '25edf1cb-ed2f-4ae2-a85d-ef5c6f0af8ea' THEN r.resposta END) AS identidade_genero,
            MAX(CASE WHEN r.id_pergunta = '32b1a387-a2a9-4f79-af30-d32026af64fe' THEN r.resposta END) AS nome_social
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
            rb.identidade_genero
        FROM turmas_filtradas tf
        JOIN processos pr ON pr.turma_id = tf.turma_id
        JOIN user_expandido ux ON ux.id = pr.user_expandido_id
        LEFT JOIN respostas_basicas rb ON rb.user_expandido_id = ux.id
        WHERE (p_tipo_candidatura IS NULL OR pr.tipo_candidatura = p_tipo_candidatura)
          AND (p_tipo_processo IS NULL OR pr.tipo_processo = p_tipo_processo)
          AND (p_status_processo IS NULL OR pr.status = p_status_processo)
    ),

    --------------------------------------------------------------------
    -- NOME FINAL (Resolução Social vs Registro)
    --------------------------------------------------------------------
    candidatos_nome AS (
        SELECT
            cb.*,
            CASE 
                WHEN cb.identidade_genero IN ('Mulher Trans','Homem Trans','Travesti','Não Binário')
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
            'alunos', (
                SELECT COALESCE(
                    jsonb_agg(
                        jsonb_build_object(
                            'id_processo', cn.processo_id,
                            'nome', cn.nome_final
                        )
                        ORDER BY cn.nome_final
                    ),
                    '[]'::jsonb
                )
                FROM candidatos_nome cn
                WHERE cn.turma_id = tf.turma_id
            )
        )
        ORDER BY tf.nome_turma
    )
    INTO v_result
    FROM turmas_filtradas tf;

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$function$
