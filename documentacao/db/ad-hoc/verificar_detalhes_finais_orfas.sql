-- 2. Relatório Detalhado
WITH user_processes_agg AS (
    SELECT
        p.user_expandido_id,
        count(*) as qtd_processos,
        -- Aggregations
        jsonb_agg(t.nome_curso) as list_nomes,
        jsonb_agg(t.id) as list_ids,
        jsonb_agg(t.area_curso) as list_areas,
        -- Single values
        max(t.nome_curso) as single_nome,
        max(t.id::text) as single_id,
        max(t.area_curso) as single_area
    FROM public.processos p
    JOIN public.turmas t ON p.turma_id = t.id
    GROUP BY p.user_expandido_id
)
SELECT 
    r.id as id_resposta,
    ue.nome as aluno,
    p.label as pergunta,
    
    -- Quantidade de Processos do Aluno
    COALESCE(upa.qtd_processos, 0) as qtd_processos,

    -- Colunas de Nome da Turma
    CASE WHEN COALESCE(upa.qtd_processos, 0) = 1 THEN upa.single_nome ELSE NULL END as nome_turma_unico,
    CASE WHEN COALESCE(upa.qtd_processos, 0) > 1 THEN upa.list_nomes ELSE '[]'::jsonb END as json_nomes_turmas,

    -- Colunas de ID da Turma
    CASE WHEN COALESCE(upa.qtd_processos, 0) = 1 THEN upa.single_id ELSE NULL END as id_turma_unico,
    CASE WHEN COALESCE(upa.qtd_processos, 0) > 1 THEN upa.list_ids ELSE '[]'::jsonb END as json_ids_turmas,

    -- Área (mostra lista completa para conferência)
    upa.list_areas as areas_turmas
    
FROM public.respostas r
JOIN public.user_expandido ue ON r.user_expandido_id = ue.id
JOIN public.perguntas p ON r.id_pergunta = p.id
LEFT JOIN user_processes_agg upa ON upa.user_expandido_id = ue.id
WHERE r.id_turma IS NULL
AND EXISTS (
    SELECT 1 FROM public.processo_documentos_obrigatorios pdo
    WHERE pdo.id_pergunta = r.id_pergunta AND pdo.escopo = 'turma'
)
ORDER BY ue.nome;
