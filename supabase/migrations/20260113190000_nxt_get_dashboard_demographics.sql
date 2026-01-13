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
    v_idade_stats json;
    
    -- Question IDs
    c_pergunta_genero uuid := '25edf1cb-ed2f-4ae2-a85d-ef5c6f0af8ea';
    c_pergunta_raca uuid := '9670c817-5db6-4055-8fc9-04cc15d6cd3e';
    c_pergunta_renda uuid := '98d09feb-ec9a-4a30-882d-7de8099c153f';
    c_pergunta_nascimento uuid := '8925bdc2-538a-408d-bd34-fb64b2638621';
    c_pergunta_pcd uuid := 'eae93308-1e4d-4c67-9c53-c9abf6a31eaf';
BEGIN
    -- 1. Status Counts
    -- Status can be NULL in database, which maps to 'Aguardando' logic in some places, 
    -- but the user said "quantas das incrições o status é Aguardando (que na tgabela é nULL".
    -- "envio_email" defaults to 'Aguardando'.
    -- The prompt says: "status text null". "quantas das incrições o status é Aguardando (que na tgabela é nULL"
    -- So count NULL as 'Aguardando'.
    
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
    -- We only care about candidates in the filtered processes
    CREATE TEMPORARY TABLE temp_candidatos AS
    SELECT DISTINCT p.user_expandido_id
    FROM processos p
    JOIN turmas t ON p.turma_id = t.id
    WHERE t.ano_semestre = p_ano_semestre
      AND p.tipo_processo = p_tipo_processo::public.tipo_processo
      AND p.tipo_candidatura = p_tipo_candidatura::public.tipo_candidatura
      AND (p_area IS NULL OR t.area_curso = p_area)
      AND p.user_expandido_id IS NOT NULL; -- Ensure we have a user link

    -- 2. Demographics Helpers
    -- We need to join with RESPOSTAS.
    -- The answers are stored in 'resposta' column (text).
    -- Some are JSON (but stored as text?), looking at the prompt:
    -- '{"label": "Mulher Cis", "value": "mulher_cis"}' -> This looks like the OPTIONS definition, not the answer.
    -- The answer usually stores the "value" (e.g. "mulher_cis").
    -- "ele aguarda a resposat do label ok é o que vai achar na coluna resposta"
    -- Wait, user says: "ele aguarda a resposat do label ok é o que vai achar na coluna resposta" -> "He waits for the response of the label ok is what you will find in the answer column".
    -- This might mean the 'resposta' column contains the LABEL? Or the VALUE?
    -- Usually it's the value. But the user said "o que importa é o label ok ?".
    -- Let's assume the 'resposta' column stores the VALUE (e.g. 'mulher_cis'), and we map it to Label in frontend OR we group by what's there.
    -- Actually, if `resposta` column is just text, we can group by it directly for now.

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

    -- Idade (Calculated)
    SELECT json_agg(json_build_object('faixa', faixa, 'qtd', qtd)) INTO v_idade_stats
    FROM (
        SELECT 
            CASE 
                WHEN age < 18 THEN '< 18'
                WHEN age BETWEEN 18 AND 24 THEN '18-24'
                WHEN age BETWEEN 25 AND 34 THEN '25-34'
                WHEN age BETWEEN 35 AND 44 THEN '35-44'
                WHEN age BETWEEN 45 AND 59 THEN '45-59'
                ELSE '60+'
            END as faixa,
            COUNT(*) as qtd
        FROM (
            SELECT EXTRACT(YEAR FROM AGE(CURRENT_DATE, r.resposta::date)) as age
            FROM respostas r
            JOIN temp_candidatos c ON r.user_expandido_id = c.user_expandido_id
            WHERE r.id_pergunta = c_pergunta_nascimento
        ) dates
        GROUP BY 1
        ORDER BY 1
    ) i;

    -- Drop temp table
    DROP TABLE temp_candidatos;

    RETURN json_build_object(
        'status_counts', COALESCE(v_status_counts, '{}'::json),
        'demographics', json_build_object(
            'genero', COALESCE(v_genero_stats, '[]'::json),
            'raca', COALESCE(v_raca_stats, '[]'::json),
            'renda', COALESCE(v_renda_stats, '[]'::json),
            'pcd', COALESCE(v_pcd_stats, '[]'::json),
            'idade', COALESCE(v_idade_stats, '[]'::json)
        )
    );
END;
$function$;
