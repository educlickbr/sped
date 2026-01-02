-- Check for duplicate questions by Label
SELECT label, count(*), array_agg(id) as ids
FROM public.perguntas
WHERE label ILIKE '%idade%'  -- Filter for 'idade' as mentioned
GROUP BY label
HAVING count(*) > 1;

-- Check for process entries (obrigatorios) that might be causing duplication in joins
-- Looking for multiple entries pointing to the same question or different questions with same label
SELECT 
    p.label, 
    pdo.escopo, 
    pdo.id_turma, 
    pdo.id_area, 
    pdo.id_pergunta
FROM public.processo_documentos_obrigatorios pdo
JOIN public.perguntas p ON pdo.id_pergunta = p.id
WHERE p.label ILIKE '%idade%'
ORDER BY p.label;
