-- Verificando configuração de Area para o processo/turma falha
SELECT 
    p.id as processo_id,
    t.id as turma_id, 
    t.nome_curso, 
    c.area as area_no_curso_tabela, -- Usado na FUNCTION
    t.area_curso as area_na_turma_tabela -- Usado nos relatórios anteriores
FROM public.processos p 
JOIN public.turmas t ON p.turma_id = t.id 
LEFT JOIN public.curso c ON t.id_curso = c.id 
WHERE p.id = 'bfc24e16-5c3e-4a6b-8e8f-7d3aecd3f588';
