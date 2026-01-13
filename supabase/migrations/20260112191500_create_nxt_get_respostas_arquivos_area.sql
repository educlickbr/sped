CREATE OR REPLACE FUNCTION public.nxt_get_respostas_arquivos_area(
    p_user_id uuid,
    p_area text,
    p_tipo_processo text,
    p_tipo_candidatura text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    v_user_nascimento text;
    v_user_idade int;
    v_doc_resposta text;
    v_pcd_resposta text;
    v_laudo_resposta text;
    v_result jsonb;
BEGIN

    -- 1. Get User Age (Logic from nxt_get_respostas_nao_arquivos_area)
    SELECT r.resposta 
    INTO v_user_nascimento 
    FROM respostas r 
    WHERE r.user_expandido_id = p_user_id 
      AND r.id_pergunta = '8925bdc2-538a-408d-bd34-fb64b2638621' -- Fixed ID for Date of Birth
    LIMIT 1;

    IF v_user_nascimento IS NOT NULL THEN 
        v_user_idade := date_part('year', age((v_user_nascimento)::timestamptz)); 
    ELSE
        v_user_idade := NULL;
    END IF;

    -- 2. Get Dependent Answers (for Rules)
    -- Doc Responsavel Answer
    SELECT resposta INTO v_doc_resposta
    FROM respostas
    WHERE user_expandido_id = p_user_id AND id_pergunta = '172bf4c5-7609-40d0-a805-d5291fdec84a'
    LIMIT 1;

    -- PCD Answer
    SELECT resposta INTO v_pcd_resposta
    FROM respostas
    WHERE user_expandido_id = p_user_id AND id_pergunta = 'eae93308-1e4d-4c67-9c53-c9abf6a31eaf'
    LIMIT 1;

    -- Laudo PCD Answer
    SELECT resposta INTO v_laudo_resposta
    FROM respostas
    WHERE user_expandido_id = p_user_id AND id_pergunta = 'de76ebe6-38d2-44e1-a112-ee64ad604c4f'
    LIMIT 1;


    -- 3. Fetch Questions and Join with Answers
    WITH obrigatorias AS (
        SELECT
            pdo.id_pergunta,
            p.pergunta,
            p.label,
            p.tipo,
            pdo.bloco,
            pdo.obrigatorio,
            pdo.ordem,
            pdo.largura, -- Using integer columns as per upgrade
            pdo.altura,  -- Using integer columns as per upgrade
            false::boolean AS artificial,
            p.opcoes
        FROM processo_documentos_obrigatorios pdo
        JOIN perguntas p ON p.id = pdo.id_pergunta
        WHERE 
            -- Filter by Area
            (pdo.escopo = 'area' AND pdo.id_area = p_area::public.tipo_area)
            
            -- Filter by Parameters
            AND (pdo.tipo_processo = p_tipo_processo::public.tipo_processo OR pdo.tipo_processo IS NULL)
            AND (pdo.tipo_candidatura = p_tipo_candidatura::public.tipo_candidatura OR pdo.tipo_candidatura IS NULL)

            -- ONLY Files/Links
            AND lower(p.tipo) IN ('arquivo', 'link')

            ----------------------------------------------------------
            -- Rule 1: Responsible Document
            ----------------------------------------------------------
            AND (
                p.id <> '172bf4c5-7609-40d0-a805-d5291fdec84a'
                OR (
                    -- Minor (or age unknown/null assume minor?) - Logic from user snippet: COALESCE(ic.idade, 0) < 18
                    COALESCE(v_user_idade, 0) < 18
                    OR v_doc_resposta IS NOT NULL
                )
            )

            ----------------------------------------------------------
            -- Rule 2: PCD Medical Report
            ----------------------------------------------------------
            AND (
                p.id <> 'de76ebe6-38d2-44e1-a112-ee64ad604c4f'
                OR (
                    (v_pcd_resposta ILIKE 'Sim')
                    OR (v_laudo_resposta IS NOT NULL)
                )
            )
    ),

    unificado AS (
        SELECT
            o.*,
            r.id AS id_resposta,
            r.resposta,
            r.arquivo_original,
            r.aprovado_doc
        FROM obrigatorias o
        LEFT JOIN LATERAL (
            SELECT * FROM respostas r
            WHERE r.id_pergunta = o.id_pergunta
              AND r.user_expandido_id = p_user_id
            ORDER BY r.criado_em DESC
            LIMIT 1
        ) r ON true
    ),

    finalizado AS (
        SELECT 
            jsonb_build_object(
                'id_pergunta', u.id_pergunta,
                'pergunta', u.pergunta,
                'label', u.label,
                'tipo', u.tipo,
                'bloco', u.bloco,
                'ordem', u.ordem,
                'obrigatorio', u.obrigatorio,
                'largura', u.largura,
                'altura', u.altura,
                'opcoes', u.opcoes,
                'artificial', u.artificial,
                'id_resposta', u.id_resposta,
                'resposta', u.resposta,
                'arquivo_original', u.arquivo_original,
                'aprovado_doc', u.aprovado_doc,
                'uploading', false,
                'deleting', false,
                'load', false
            ) AS item
        FROM unificado u
    )

    SELECT COALESCE(
        jsonb_agg(item ORDER BY (item->>'ordem')::int NULLS LAST),
        '[]'::jsonb
    )
    INTO v_result
    FROM finalizado;

    RETURN v_result;

END;
$function$;
