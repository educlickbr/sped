-- INVESTIGAÇÃO PROFUNDA DOS 82 CASOS INVALIDOS
-- Para cada resposta que está num lugar "errado" (segundo a validação), vamos ver:
-- 1. Quais turmas o aluno tem?
-- 2. Dessas turmas, quais EXIGEM essa pergunta?
-- 3. Dessas que exigem, alguma já tem resposta?
-- 4. Qual a distância temporal para cada uma?

WITH RespostasInvalidas AS (
    SELECT 
        r.id AS id_resposta,
        r.user_expandido_id,
        r.id_pergunta,
        r.id_turma AS id_turma_atual,
        t.nome_curso AS nome_turma_atual,
        r.criado_em AS data_resposta
    FROM public.respostas r
    JOIN public.turmas t ON r.id_turma = t.id
    WHERE t.ano_semestre = '26Is'
    -- Filtro de Invalidade (Cópia da verificação)
    AND NOT EXISTS (
        SELECT 1 
        FROM public.processo_documentos_obrigatorios pdo
        WHERE pdo.id_pergunta = r.id_pergunta
          AND pdo.escopo = 'turma'
          AND (
              pdo.id_turma = r.id_turma
              OR 
              (pdo.id_turma IS NULL AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(t.area_curso))
          )
    )
    AND EXISTS (SELECT 1 FROM public.processo_documentos_obrigatorios pdo WHERE pdo.id_pergunta = r.id_pergunta AND pdo.escopo = 'turma')
)
SELECT 
    ue.nome AS aluno_nome,
    p.label AS pergunta,
    ri.nome_turma_atual AS "ONDE ESTA (INVALIDO)",
    
    -- JSON com a análise de todas as turmas do aluno
    jsonb_agg(
        jsonb_build_object(
            'turma', t.nome_curso,
            'area', t.area_curso,
            'requires_question', CASE WHEN EXISTS (
                SELECT 1 FROM public.processo_documentos_obrigatorios pdo 
                WHERE pdo.id_pergunta = ri.id_pergunta 
                  AND pdo.escopo = 'turma'
                  AND (pdo.id_turma = t.id OR (pdo.id_turma IS NULL AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(t.area_curso)))
            ) THEN true ELSE false END,
            'has_answer_here', CASE WHEN EXISTS (
                 SELECT 1 FROM public.respostas r2 
                 WHERE r2.user_expandido_id = ri.user_expandido_id 
                   AND r2.id_pergunta = ri.id_pergunta 
                   AND r2.id_turma = t.id
            ) THEN true ELSE false END,
            'time_gap_seconds', ABS(EXTRACT(EPOCH FROM (proc.created_at - ri.data_resposta)))
        ) ORDER BY ABS(EXTRACT(EPOCH FROM (proc.created_at - ri.data_resposta))) ASC
    ) AS "ANALISE_OPCOES_ALUNO"

FROM RespostasInvalidas ri
JOIN public.user_expandido ue ON ri.user_expandido_id = ue.id
JOIN public.perguntas p ON ri.id_pergunta = p.id
-- Join com todos os processos do aluno para ver as opções
JOIN public.processos proc ON proc.user_expandido_id = ri.user_expandido_id
JOIN public.turmas t ON proc.turma_id = t.id
WHERE t.ano_semestre = '26Is'
GROUP BY ri.id_resposta, ue.nome, p.label, ri.nome_turma_atual;
