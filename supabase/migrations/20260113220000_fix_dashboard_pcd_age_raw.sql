CREATE OR REPLACE FUNCTION public.nxt_get_dashboard_demographics(
    p_ano_semestre text,
    p_tipo_processo text DEFAULT 'seletivo',
    p_tipo_candidatura text DEFAULT 'estudante',
    p_area text DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
AS $function$
DECLARE
    v_status_counts json;
    v_genero_stats json;
    v_raca_stats json;
    v_renda_stats json;
    v_pcd_stats json;
    v_nascimentos json;
    
    -- Question IDs
    c_pergunta_genero uuid := '25edf1cb-ed2f-4ae2-a85d-ef5c6f0af8ea';
    c_pergunta_raca uuid := '9670c817-5db6-4055-8fc9-04cc15d6cd3e';
    c_pergunta_renda uuid := '98d09feb-ec9a-4a30-882d-7de8099c153f';
    c_pergunta_nascimento uuid := '8925bdc2-538a-408d-bd34-fb64b2638621';
    c_pergunta_pcd uuid := 'eae93308-1e4d-4c67-9c53-c9abf6a31eaf';
BEGIN
    -- 1. Status Counts
    SELECT json_object_agg(
        COALESCE(status, 'Aguardando'),
        qtd
    ) INTO v_status_counts
    FROM (
        SELECT 
            p.status,
            COUNT(*) as qtd
        FROM processos p
        JOIN turmas t ON p.turma_id = t.id
        WHERE t.ano_semestre = p_ano_semestre
          AND p.tipo_processo = p_tipo_processo::public.tipo_processo
          AND p.tipo_candidatura = p_tipo_candidatura::public.tipo_candidatura
          AND (p_area IS NULL OR t.area_curso = p_area)
        GROUP BY p.status
    ) s;

    -- CTE for target candidates (user_expandido_id) to simplify subsequent queries
    CREATE TEMPORARY TABLE temp_candidatos AS
    SELECT DISTINCT p.user_expandido_id
    FROM processos p
    JOIN turmas t ON p.turma_id = t.id
    WHERE t.ano_semestre = p_ano_semestre
      AND p.tipo_processo = p_tipo_processo::public.tipo_processo
      AND p.tipo_candidatura = p_tipo_candidatura::public.tipo_candidatura
      AND (p_area IS NULL OR t.area_curso = p_area)
      AND p.user_expandido_id IS NOT NULL; 

    -- 2. Demographics Helpers

    -- Gênero
    SELECT json_agg(json_build_object('label', resposta, 'qtd', qtd)) INTO v_genero_stats
    FROM (
        SELECT r.resposta, COUNT(*) as qtd
        FROM respostas r
        JOIN temp_candidatos c ON r.user_expandido_id = c.user_expandido_id
        WHERE r.id_pergunta = c_pergunta_genero
        GROUP BY r.resposta
    ) g;

    -- Raça
    SELECT json_agg(json_build_object('label', resposta, 'qtd', qtd)) INTO v_raca_stats
    FROM (
        SELECT r.resposta, COUNT(*) as qtd
        FROM respostas r
        JOIN temp_candidatos c ON r.user_expandido_id = c.user_expandido_id
        WHERE r.id_pergunta = c_pergunta_raca
        GROUP BY r.resposta
    ) r;

    -- Renda
    SELECT json_agg(json_build_object('label', resposta, 'qtd', qtd)) INTO v_renda_stats
    FROM (
        SELECT r.resposta, COUNT(*) as qtd
        FROM respostas r
        JOIN temp_candidatos c ON r.user_expandido_id = c.user_expandido_id
        WHERE r.id_pergunta = c_pergunta_renda
        GROUP BY r.resposta
    ) rn;

    -- PCD
    SELECT json_agg(json_build_object('label', resposta, 'qtd', qtd)) INTO v_pcd_stats
    FROM (
        SELECT r.resposta, COUNT(*) as qtd
        FROM respostas r
        JOIN temp_candidatos c ON r.user_expandido_id = c.user_expandido_id
        WHERE r.id_pergunta = c_pergunta_pcd
        GROUP BY r.resposta
    ) p;

    -- Nascimentos (Raw list for client-side calc)
    -- We select just the raw string to let the client handle parsing
    SELECT json_agg(r.resposta) INTO v_nascimentos
    FROM respostas r
    JOIN temp_candidatos c ON r.user_expandido_id = c.user_expandido_id
    WHERE r.id_pergunta = c_pergunta_nascimento
      AND r.resposta IS NOT NULL;

    -- Drop temp table
    DROP TABLE temp_candidatos;

    RETURN json_build_object(
        'status_counts', COALESCE(v_status_counts, '{}'::json),
        'demographics', json_build_object(
            'genero', COALESCE(v_genero_stats, '[]'::json),
            'raca', COALESCE(v_raca_stats, '[]'::json),
            'renda', COALESCE(v_renda_stats, '[]'::json),
            'pcd', COALESCE(v_pcd_stats, '[]'::json),
            'idade', '[]'::json, -- Deprecated in favor of client-side calc
            'nascimentos', COALESCE(v_nascimentos, '[]'::json)
        )
    );
END;
$function$;
