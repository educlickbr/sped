-- INVESTIGAÇÃO ALUNO RECENTE (64819f31-be36-4231-ba8c-705a06f0f0d5)

-- 1. Quais processos ele tem?
SELECT 
    ue.nome,
    p.id as id_processo,
    t.nome_curso,
    t.area_curso,
    t.ano_semestre,
    p.created_at as processo_criado_em
FROM public.processos p
JOIN public.turmas t ON p.turma_id = t.id
JOIN public.user_expandido ue ON p.user_expandido_id = ue.id
WHERE p.user_expandido_id = '64819f31-be36-4231-ba8c-705a06f0f0d5'
ORDER BY p.created_at DESC;

-- 2. Quais respostas ele tem?
SELECT 
    r.id,
    p.label as pergunta,
    t.nome_curso as vinculado_a_turma,
    t.ano_semestre,
    r.criado_em,
    r.atualizado_em
FROM public.respostas r
LEFT JOIN public.turmas t ON r.id_turma = t.id
JOIN public.perguntas p ON r.id_pergunta = p.id
WHERE r.user_expandido_id = '64819f31-be36-4231-ba8c-705a06f0f0d5'
ORDER BY r.criado_em DESC;

-- 3. Check de Obrigatoriedade (Onde DEVERIA ter resposta)
SELECT 
    t.nome_curso,
    p.label as pergunta_obrigatoria,
    CASE WHEN EXISTS (
        SELECT 1 FROM public.respostas r 
        WHERE r.user_expandido_id = '64819f31-be36-4231-ba8c-705a06f0f0d5'
          AND r.id_pergunta = pdo.id_pergunta
          AND r.id_turma = t.id
    ) THEN 'OK' ELSE 'FALTANTE' END as status
FROM public.processos proc
JOIN public.turmas t ON proc.turma_id = t.id
JOIN public.processo_documentos_obrigatorios pdo 
    ON pdo.escopo = 'turma'
    AND (pdo.id_turma = t.id OR (pdo.id_turma IS NULL AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(t.area_curso)))
JOIN public.perguntas p ON pdo.id_pergunta = p.id
WHERE proc.user_expandido_id = '64819f31-be36-4231-ba8c-705a06f0f0d5';
