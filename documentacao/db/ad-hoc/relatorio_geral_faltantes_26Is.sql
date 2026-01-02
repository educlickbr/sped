-- RELATÓRIO DE RESPOSTAS FALTANTES (GAP) EM 26Is
-- Lista alunos que TÊM um processo em 26Is que EXIGE uma pergunta de 'turma',
-- mas NÃO TÊM a resposta vinculada a essa turma.

-- QUERY 1: LISTA DETALHADA SEM DUPLICATAS
SELECT DISTINCT
    ue.id AS user_expandido_id,
    ue.nome AS aluno_nome,
    t.nome_curso AS curso,
    p.label AS pergunta_faltante,
    to_char(proc.created_at, 'DD/MM/YYYY HH24:MI:SS') AS data_processo,
    public.normalizar_texto(t.area_curso) AS area_curso,
    proc.created_at -- Mantido para ordenaÃ§Ã£o correta
FROM public.processos proc
JOIN public.user_expandido ue ON proc.user_expandido_id = ue.id
JOIN public.turmas t ON proc.turma_id = t.id
-- Join com as regras de obrigatoriedade (PDO)
JOIN public.processo_documentos_obrigatorios pdo 
    ON pdo.escopo = 'turma'
    AND (
        pdo.id_turma = t.id 
        OR 
        (pdo.id_turma IS NULL AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(t.area_curso))
    )
JOIN public.perguntas p ON pdo.id_pergunta = p.id
-- Left Join para ver se JÁ EXISTE resposta
LEFT JOIN public.respostas r 
    ON r.user_expandido_id = proc.user_expandido_id
    AND r.id_pergunta = pdo.id_pergunta
    AND r.id_turma = t.id -- Tem que estar na turma certa
WHERE 
    t.ano_semestre = '26Is'
    AND r.id IS NULL -- SÓ QUEREMOS QUEM NÃO TEM RESPOSTA
ORDER BY proc.created_at DESC, ue.nome;

-- QUERY 2: TOTAL DE ALUNOS AFETADOS
SELECT COUNT(DISTINCT proc.user_expandido_id) as total_alunos_afetados
FROM public.processos proc
JOIN public.turmas t ON proc.turma_id = t.id
JOIN public.processo_documentos_obrigatorios pdo 
    ON pdo.escopo = 'turma'
    AND (
        pdo.id_turma = t.id 
        OR 
        (pdo.id_turma IS NULL AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(t.area_curso))
    )
LEFT JOIN public.respostas r 
    ON r.user_expandido_id = proc.user_expandido_id
    AND r.id_pergunta = pdo.id_pergunta
    AND r.id_turma = t.id
WHERE 
    t.ano_semestre = '26Is'
    AND r.id IS NULL;
