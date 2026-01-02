-- Debug PDO Configuration for specific questions
SELECT 
    p.label,
    pdo.id_pergunta,
    pdo.escopo,
    pdo.id_area,
    pdo.id_turma,
    public.normalizar_texto(pdo.id_area::text) as area_norm_pdo
FROM public.processo_documentos_obrigatorios pdo
JOIN public.perguntas p ON pdo.id_pergunta = p.id
WHERE p.label ILIKE '%Por que voc%';
