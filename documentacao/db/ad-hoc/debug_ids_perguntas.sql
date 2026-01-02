-- Verificando se temos Multiplas Perguntas com o mesmo Label
SELECT 
    p.id as id_pergunta,
    p.label,
    pdo.id as id_pdo,
    pdo.id_area,
    pdo.id_turma
FROM public.processo_documentos_obrigatorios pdo
JOIN public.perguntas p ON pdo.id_pergunta = p.id
WHERE p.label ILIKE '%Carta de inten%';

-- Verificando qual ID de pergunta o aluno RESPONDEU
SELECT 
    r.id as id_resposta,
    r.id_pergunta,
    p.label,
    r.id_turma,
    t.nome_curso
FROM public.respostas r
JOIN public.perguntas p ON r.id_pergunta = p.id
LEFT JOIN public.turmas t ON r.id_turma = t.id
WHERE r.user_expandido_id = '64819f31-be36-4231-ba8c-705a06f0f0d5'
  AND p.label ILIKE '%Carta de inten%';
