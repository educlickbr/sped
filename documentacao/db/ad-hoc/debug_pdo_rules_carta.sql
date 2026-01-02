-- Debug PDO Rules for Carta
SELECT 
    pdo.id,
    p.label, 
    pdo.escopo, 
    pdo.id_area, 
    pdo.id_turma
FROM public.processo_documentos_obrigatorios pdo
JOIN public.perguntas p ON pdo.id_pergunta = p.id
WHERE p.label ILIKE '%Carta de inten%';
