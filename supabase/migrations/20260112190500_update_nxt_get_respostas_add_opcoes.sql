CREATE OR REPLACE FUNCTION public.nxt_get_respostas_nao_arquivos_area(
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
    v_user_nome text;
    v_user_sobrenome text;
    v_user_email text;
    v_perguntas jsonb;
    v_user_nascimento text;
    v_user_idade int;
BEGIN
    -- 1) USER EXPANDIDO INFO (for artificial fields)
    SELECT ue.nome, ue.sobrenome, ue.email 
    INTO v_user_nome, v_user_sobrenome, v_user_email 
    FROM user_expandido ue 
    WHERE ue.id = p_user_id;

    -- 2) IDADE CALCULATION (needed for filtering some questions like responsible doc)
    SELECT r.resposta 
    INTO v_user_nascimento 
    FROM respostas r 
    WHERE r.user_expandido_id = p_user_id 
      AND r.id_pergunta = '8925bdc2-538a-408d-bd34-fb64b2638621' -- Fixed ID for Date of Birth
    LIMIT 1;

    IF v_user_nascimento IS NOT NULL THEN 
        v_user_idade := date_part('year', age((v_user_nascimento)::timestamptz)); 
    END IF;

    -- 3) PERGUNTAS OBRIGATÓRIAS (NON-FILES)
    WITH obrig AS (
        SELECT DISTINCT
            pdo.id, 
            pdo.id_pergunta, 
            pdo.bloco, 
            pdo.ordem, 
            pdo.obrigatorio, 
            pdo.largura, 
            pdo.altura, 
            pdo.depende, 
            pdo.depende_de, 
            pdo.valor_depende, 
            pdo.pergunta_gatilho, 
            pdo.valor_gatilho,
            pdo.tipo_processo, 
            pdo.tipo_candidatura,
            p.pergunta, 
            p.label, 
            p.tipo,
            p.opcoes, -- Added opcoes column
            pdo.escopo
        FROM processo_documentos_obrigatorios pdo
        JOIN perguntas p ON p.id = pdo.id_pergunta
        WHERE 
            -- Filter by Area Scope
            (pdo.escopo = 'area' AND pdo.id_area = p_area::public.tipo_area)
            
            -- Filter by Type Processo and Candidatura
            AND (pdo.tipo_processo = p_tipo_processo::public.tipo_processo OR pdo.tipo_processo IS NULL)
            AND (pdo.tipo_candidatura = p_tipo_candidatura::public.tipo_candidatura OR pdo.tipo_candidatura IS NULL)

            -- Filter OUT 'arquivo' and 'link' types
            AND p.tipo NOT IN ('arquivo', 'link')
    ),

    -- 4) USER RESPONSES
    resp AS (
        SELECT 
            id_pergunta, 
            resposta, 
            aprovado_doc, 
            motivo_reprovacao_doc, 
            arquivo_original, 
            id_turma, 
            criado_em,
            id AS id_resposta
        FROM respostas
        WHERE user_expandido_id = p_user_id
    ),
    
    -- 5) ARTIFICIAL FIELDS
    fake AS (
        SELECT * FROM (
            VALUES
            (gen_random_uuid(), 'nome', 'Nome', 'texto', 'dados_pessoais'::bloco_pergunta, 1, false, 1, 36, false, NULL, v_user_nome, true, null::jsonb),
            (gen_random_uuid(), 'sobrenome', 'Sobrenome', 'texto', 'dados_pessoais'::bloco_pergunta, 2, false, 1, 36, false, NULL, v_user_sobrenome, true, null::jsonb),
            (gen_random_uuid(), 'email', 'E-mail', 'texto', 'dados_pessoais'::bloco_pergunta, 3, false, 2, 36, false, NULL, v_user_email, true, null::jsonb)
        ) AS t(id_pergunta, pergunta, label, tipo, bloco, ordem, obrigatorio, largura, altura, depende, depende_de, resposta, artificial, opcoes)
    )

    -- 6) AGGREGATE RESULTS
    SELECT jsonb_agg(
        jsonb_build_object(
            'id_pergunta', x.id_pergunta,
            'pergunta', x.pergunta,
            'label', x.label,
            'tipo', x.tipo,
            'bloco', x.bloco,
            'ordem', x.ordem,
            'obrigatorio', x.obrigatorio,
            'largura', x.largura,
            'altura', x.altura,
            'depende', x.depende,
            'depende_de', x.depende_de,
            'valor_depende', x.valor_depende,
            'pergunta_gatilho', x.pergunta_gatilho,
            'valor_gatilho', x.valor_gatilho,
            'tipo_processo', x.tipo_processo,
            'tipo_candidatura', x.tipo_candidatura,
            'resposta', x.resposta,
            'id_resposta', x.id_resposta,
            'arquivo_original', x.arquivo_original,
            'aprovado_doc', x.aprovado_doc,
            'artificial', x.artificial,
            'escopo_original', x.escopo,
            'opcoes', x.opcoes, -- Include options in JSON
            'uploading', false,
            'deleting', false,
            'load', false
        )
        ORDER BY x.bloco, x.ordem
    )
    INTO v_perguntas
    FROM (
        -- Real Questions
        SELECT 
            o.*, 
            false AS artificial,
            r.resposta, 
            r.id_resposta,
            r.arquivo_original, 
            r.aprovado_doc
        FROM obrig o
        LEFT JOIN LATERAL (
            SELECT r.*
            FROM resp r
            WHERE r.id_pergunta = o.id_pergunta
            ORDER BY r.criado_em DESC -- Get latest answer
            LIMIT 1
        ) r ON true

        UNION ALL
        
        -- Artificial Questions
        SELECT
            NULL as id, 
            f.id_pergunta, 
            f.bloco, 
            f.ordem, 
            false as obrigatorio, 
            f.largura, 
            f.altura, 
            false as depende, 
            NULL as depende_de, 
            NULL as valor_depende, 
            false as pergunta_gatilho, 
            NULL as valor_gatilho, 
            NULL as tipo_processo, 
            NULL as tipo_candidatura,
            f.pergunta, 
            f.label, 
            f.tipo, 
            f.opcoes,
            'area'::escopo_processo, -- Fake scope
            true as artificial, 
            f.resposta, 
            NULL as id_resposta,
            NULL as arquivo_original, 
            NULL as aprovado_doc
        FROM fake f
    ) x;

    -- 7) FILTER LOGIC (e.g., Hide Responsible Legal if user is adult)
    IF v_user_idade IS NOT NULL AND v_user_idade >= 18 THEN
        v_perguntas := (SELECT jsonb_agg(elem) FROM jsonb_array_elements(v_perguntas) elem WHERE elem->>'bloco' <> 'responsavel_legal');
    END IF;

    RETURN coalesce(v_perguntas, '[]'::jsonb);
END;
$function$;
