-- Fix: ensure nxt_get_respostas_usuario_turma returns consistent columns and includes ordem_bloco
-- This migration replaces the function only; it avoids editing previous migrations.
CREATE OR REPLACE FUNCTION public.nxt_get_respostas_usuario_turma(p_user_id uuid, p_turma_id uuid, p_tipo_processo tipo_processo DEFAULT NULL::tipo_processo, p_tipo_candidatura tipo_candidatura DEFAULT NULL::tipo_candidatura)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_turma RECORD;
    v_curso RECORD;
    v_area text;
    v_semestre_humanizado text;
    v_user_nascimento text;
    v_user_idade int;

    v_user_nome text;
    v_user_sobrenome text;
    v_user_email text;

    v_perguntas jsonb;
BEGIN
    SELECT * INTO v_turma FROM turmas WHERE id = p_turma_id;
    SELECT * INTO v_curso FROM curso WHERE id = v_turma.id_curso;
    v_area := (v_curso.area)::text;

    v_semestre_humanizado :=
        CASE
            WHEN v_turma.ano_semestre ~ '^[0-9]{2}Is$' THEN 'Primeiro semestre de 20' || substring(v_turma.ano_semestre, 1, 2)
            WHEN v_turma.ano_semestre ~ '^[0-9]{2}IIs$' THEN 'Segundo semestre de 20' || substring(v_turma.ano_semestre, 1, 2)
            ELSE v_turma.ano_semestre
        END;

    SELECT ue.nome, ue.sobrenome, ue.email INTO v_user_nome, v_user_sobrenome, v_user_email FROM user_expandido ue WHERE ue.id = p_user_id;

    SELECT r.resposta INTO v_user_nascimento FROM respostas r WHERE r.user_expandido_id = p_user_id AND r.id_pergunta = '8925bdc2-538a-408d-bd34-fb64b2638621' AND r.id_turma IS NULL LIMIT 1;
    IF v_user_nascimento IS NOT NULL THEN v_user_idade := date_part('year', age((v_user_nascimento)::timestamptz)); END IF;

    WITH obrig AS (
        SELECT DISTINCT
            pdo.id,
            pdo.id_pergunta,
            pdo.bloco,
            pdo.ordem,
            pdo.ordem_bloco,
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
            p.opcoes,
            pdo.escopo
        FROM processo_documentos_obrigatorios pdo
        JOIN perguntas p ON p.id = pdo.id_pergunta
        WHERE 
            (
                (pdo.escopo = 'area' AND pdo.id_area = v_area::public.tipo_area)
                OR
                (
                    pdo.escopo = 'turma' 
                    AND (
                           pdo.id_turma = p_turma_id 
                        OR (pdo.id_turma IS NULL AND pdo.id_area = v_area::public.tipo_area)
                    )
                )
            )
            AND (pdo.tipo_processo = p_tipo_processo OR p_tipo_processo IS NULL)
            AND (pdo.tipo_candidatura = p_tipo_candidatura OR p_tipo_candidatura IS NULL)
    ),

    resp AS (
        SELECT id_pergunta, resposta, aprovado_doc, motivo_reprovacao_doc, arquivo_original, id_turma, criado_em
        FROM respostas
        WHERE user_expandido_id = p_user_id
    ),

    fake AS (
        SELECT * FROM (
            VALUES
            (
                gen_random_uuid(), 'nome', 'Nome', 'texto', 'dados_pessoais'::bloco_pergunta, 1, NULL, false, 1, 36, false, NULL, NULL::jsonb, false::boolean, NULL::text, NULL::tipo_processo, NULL::tipo_candidatura, NULL::jsonb, NULL::escopo_processo, v_user_nome, NULL::text, NULL::boolean, true
            ),
            (
                gen_random_uuid(), 'sobrenome', 'Sobrenome', 'texto', 'dados_pessoais'::bloco_pergunta, 2, NULL, false, 1, 36, false, NULL, NULL::jsonb, false::boolean, NULL::text, NULL::tipo_processo, NULL::tipo_candidatura, NULL::jsonb, NULL::escopo_processo, v_user_sobrenome, NULL::text, NULL::boolean, true
            ),
            (
                gen_random_uuid(), 'email', 'E-mail', 'texto', 'dados_pessoais'::bloco_pergunta, 3, NULL, false, 2, 36, false, NULL, NULL::jsonb, false::boolean, NULL::text, NULL::tipo_processo, NULL::tipo_candidatura, NULL::jsonb, NULL::escopo_processo, v_user_email, NULL::text, NULL::boolean, true
            )
        ) AS t(
            id_pergunta, pergunta, label, tipo, bloco, ordem, ordem_bloco, obrigatorio, largura, altura, depende, depende_de, valor_depende, pergunta_gatilho, valor_gatilho, tipo_processo, tipo_candidatura, opcoes, escopo, resposta, arquivo_original, aprovado_doc, artificial
        )
    )

    SELECT jsonb_agg(
        jsonb_build_object(
            'id_pergunta', x.id_pergunta,
            'pergunta', x.pergunta,
            'label', x.label,
            'tipo', x.tipo,
            'bloco', x.bloco,
            'ordem', x.ordem,
            'ordem_bloco', x.ordem_bloco,
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
            'arquivo_original', x.arquivo_original,
            'aprovado_doc', x.aprovado_doc,
            'artificial', x.artificial,
            'escopo_original', x.escopo,
            'opcoes', x.opcoes,
            'uploading', false,
            'deleting', false,
            'load', false
        )
        ORDER BY x.bloco, COALESCE(x.ordem_bloco, x.ordem)
    )
    INTO v_perguntas
    FROM (
        SELECT 
            o.id_pergunta, o.pergunta, o.label, o.tipo, o.bloco, o.ordem, o.ordem_bloco, o.obrigatorio, o.largura, o.altura, o.depende, o.depende_de, o.valor_depende, o.pergunta_gatilho, o.valor_gatilho, o.tipo_processo, o.tipo_candidatura, o.opcoes, o.escopo,
            r.resposta, r.arquivo_original, r.aprovado_doc, false AS artificial
        FROM obrig o
        LEFT JOIN LATERAL (
            SELECT r.*
            FROM resp r
            WHERE r.id_pergunta = o.id_pergunta
            AND (
                (o.escopo = 'area')
                OR
                (o.escopo = 'turma' AND r.id_turma = p_turma_id)
            )
            ORDER BY r.criado_em ASC
            LIMIT 1
        ) r ON true

        UNION ALL

        SELECT
            f.id_pergunta, f.pergunta, f.label, f.tipo, f.bloco, f.ordem, f.ordem_bloco, f.obrigatorio, f.largura, f.altura, f.depende, f.depende_de, f.valor_depende, f.pergunta_gatilho, f.valor_gatilho, f.tipo_processo, f.tipo_candidatura, f.opcoes, f.escopo,
            f.resposta, f.arquivo_original, f.aprovado_doc, f.artificial
        FROM fake f
    ) x;

    IF v_user_idade IS NOT NULL AND v_user_idade >= 18 THEN
        v_perguntas := (SELECT jsonb_agg(elem) FROM jsonb_array_elements(v_perguntas) elem WHERE elem->>'bloco' <> 'responsavel_legal');
    END IF;

    RETURN jsonb_build_object(
        'curso', v_curso.nome_curso,
        'area', v_area,
        'semestre', v_semestre_humanizado,
        'data_inicio', v_turma.dt_ini_curso,
        'data_fim', v_turma.dt_fim_curso,
        'idade_usuario', v_user_idade,
        'perguntas', v_perguntas
    );
END;
$function$;
