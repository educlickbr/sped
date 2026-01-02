-- DIAGNOSTICO COMPLETO DE ALUNO UNICO (O PRIMEIRO COM ERRO)
-- Gera 2 Relatórios:
-- 1. Matriz de Processos: Para cada turma do aluno, quais perguntas são obrigatórias e se já foram respondidas.
-- 2. Auditoria de Respostas: Lista todas as respostas do aluno e se estão "sobrando" (Orfãs) ou mal alocadas.

WITH TargetUser AS (
    -- Seleciona 1 aluno que ainda tem resposta com escopo invalido
    SELECT DISTINCT r.user_expandido_id
    FROM public.respostas r
    JOIN public.turmas t ON r.id_turma = t.id
    WHERE t.ano_semestre = '26Is'
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
    LIMIT 1
)
-- RELATÓRIO 1: Matriz de Processos e Pendências
SELECT 
    'MATRIZ_PROCESSOS' as tipo_relatorio,
    tu.user_expandido_id,
    ue.nome as aluno,
    t.nome_curso as turma,
    public.normalizar_texto(t.area_curso) as area,
    p.label as pergunta_obrigatoria,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM public.respostas r 
            WHERE r.user_expandido_id = tu.user_expandido_id 
              AND r.id_pergunta = pdo.id_pergunta
              AND r.id_turma = t.id -- Está vinculada a ESTA turma?
        ) THEN 'RESPONDIDO (Vinculado)'
        
        WHEN EXISTS (
             SELECT 1 FROM public.respostas r 
            WHERE r.user_expandido_id = tu.user_expandido_id 
              AND r.id_pergunta = pdo.id_pergunta
        ) THEN 'TEM RESPOSTA (Mas em outra turma/solta)'
        
        ELSE 'PENDENTE'
    END as status_requisito
FROM TargetUser tu
JOIN public.user_expandido ue ON tu.user_expandido_id = ue.id
JOIN public.processos proc ON proc.user_expandido_id = tu.user_expandido_id
JOIN public.turmas t ON proc.turma_id = t.id
JOIN public.processo_documentos_obrigatorios pdo ON pdo.escopo = 'turma' 
    AND (pdo.id_turma = t.id OR (pdo.id_turma IS NULL AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(t.area_curso)))
JOIN public.perguntas p ON pdo.id_pergunta = p.id
WHERE t.ano_semestre = '26Is'

UNION ALL

-- RELATÓRIO 2: Auditoria das Respostas Existentes
SELECT 
    'AUDITORIA_RESPOSTAS' as tipo_relatorio,
    tu.user_expandido_id,
    ue.nome as aluno,
    COALESCE(t.nome_curso, 'SEM TURMA (NULL)') as onde_estou,
    public.normalizar_texto(t.area_curso) as area_onde_estou,
    p.label as pergunta,
    CASE 
        WHEN t.id IS NULL THEN 'ORFA (Sem vinculo)'
        WHEN NOT EXISTS (
            SELECT 1 FROM public.processo_documentos_obrigatorios pdo 
            WHERE pdo.id_pergunta = r.id_pergunta
              AND pdo.escopo = 'turma' 
              AND (pdo.id_turma = t.id OR (pdo.id_turma IS NULL AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(t.area_curso)))
        ) THEN 'INVALIDO (Turma nao exige)'
        ELSE 'VALIDO'
    END as status_validade
FROM TargetUser tu
JOIN public.user_expandido ue ON tu.user_expandido_id = ue.id
JOIN public.respostas r ON r.user_expandido_id = tu.user_expandido_id
JOIN public.perguntas p ON r.id_pergunta = p.id
LEFT JOIN public.turmas t ON r.id_turma = t.id
WHERE 
    -- Filtra apenas perguntas de turma para nao poluir com globais
    EXISTS (SELECT 1 FROM public.processo_documentos_obrigatorios pdo_chk WHERE pdo_chk.id_pergunta = r.id_pergunta AND pdo_chk.escopo = 'turma')

ORDER BY 1 DESC, 3, 5;
