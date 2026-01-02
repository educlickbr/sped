-- CHECAGEM FINAL: Pq 'Por que voce' funcionou e 'Carta' nao?

-- 1. Ver se existe resposta GLOBAL para a Carta (id = NULL) criada recentemente
SELECT id, id_pergunta, resposta, criado_em, id_turma 
FROM public.respostas 
WHERE user_expandido_id = '64819f31-be36-4231-ba8c-705a06f0f0d5'
AND id_pergunta IN (
    SELECT id FROM public.perguntas WHERE label ILIKE '%Carta de inten%'
)
ORDER BY criado_em DESC;

-- 2. Ver regras do PDO para essas duas perguntas
SELECT 
    p.label, 
    pdo.escopo, 
    pdo.id_area, -- ENUM
    pdo.id_turma
FROM public.processo_documentos_obrigatorios pdo
JOIN public.perguntas p ON pdo.id_pergunta = p.id
WHERE p.label ILIKE '%Carta de inten%' OR p.label ILIKE 'Por que voc%';
