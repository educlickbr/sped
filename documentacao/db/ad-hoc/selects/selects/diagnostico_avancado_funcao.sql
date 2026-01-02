-- Diagnostico Avancado: Simulacao da funcao _verificar_um_bloco
-- Este script tenta replicar a logica EXATA da funcao do banco de dados.

WITH VARS AS (
    SELECT 
        'b1d7ef07-b69c-440c-b2fc-7d7e2b8b9114'::uuid as target_ux_id,
        'dados_pessoais'::text as target_bloco
),
contexto_aluno AS (
    -- Tenta descobrir a turma e area do aluno pela matricula mais recente
    SELECT 
        m.id_turma,
        t.area_curso::text as area_aluno -- Assumindo que area_curso mapeia para tipo_area
    FROM public.matriculas m
    JOIN public.turmas t ON t.id = m.id_turma
    WHERE m.id_aluno = (SELECT target_ux_id FROM VARS)
    ORDER BY m.criado_em DESC
    LIMIT 1
),
obrigatorias AS (
    SELECT
        pdo.id_pergunta,
        p.label,
        p.pergunta,
        pdo.escopo,
        pdo.id_area, -- para debug
        pdo.id_turma -- para debug
    FROM public.processo_documentos_obrigatorios pdo
    JOIN public.perguntas p ON p.id = pdo.id_pergunta
    CROSS JOIN VARS
    CROSS JOIN contexto_aluno ctx
    WHERE 
        -- 1. Bloco match
        p.bloco::text = VARS.target_bloco
        AND pdo.bloco::text = VARS.target_bloco
        
        -- 2. Deve ser obrigatorio
        AND pdo.obrigatorio = true
        
        -- 3. Contexto (Area ou Turma)
        AND (
               (pdo.escopo = 'area'  AND pdo.id_area::text  = ctx.area_aluno) -- Cast para text para comparacao segura
            OR (pdo.escopo = 'turma' AND pdo.id_turma = ctx.id_turma)
        )
        
        -- 4. Dependencias
        AND (
              pdo.depende = false
           OR (
                pdo.depende = true
                AND pdo.depende_de IS NOT NULL
                AND EXISTS (
                    SELECT 1
                    FROM public.respostas r2
                    WHERE r2.user_expandido_id = VARS.target_ux_id
                      AND r2.id_pergunta = pdo.depende_de
                      AND r2.resposta IN (
                          SELECT jsonb_array_elements_text(pdo.valor_depende)
                      )
                )
           )
        )
),
respostas_user AS (
    SELECT DISTINCT ON (r.id_pergunta)
        r.id_pergunta,
        r.resposta,
        r.criado_em
    FROM public.respostas r
    CROSS JOIN VARS
    WHERE r.user_expandido_id = VARS.target_ux_id
    ORDER BY r.id_pergunta, r.criado_em DESC
),
analise_final AS (
    SELECT 
        o.id_pergunta,
        o.label,
        o.pergunta,
        o.escopo,
        r.resposta,
        CASE 
            WHEN r.resposta IS NULL THEN 'MISSING_NULL'
            WHEN trim(r.resposta) = '' THEN 'MISSING_EMPTY_STRING'
            WHEN trim(r.resposta) = '[]' THEN 'MISSING_EMPTY_ARRAY'
            WHEN trim(r.resposta) = '{}' THEN 'MISSING_EMPTY_OBJ'
            ELSE 'OK'
        END as status_validacao
    FROM obrigatorias o
    LEFT JOIN respostas_user r ON r.id_pergunta = o.id_pergunta
)
SELECT * 
FROM analise_final
-- Se quiser ver so os erros, descomente abaixo:
-- WHERE status_validacao LIKE 'MISSING%'
ORDER BY status_validacao DESC;
