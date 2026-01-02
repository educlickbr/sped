-- 1. Remove registros do aluno duplicado que causariam conflito de unicidade (uq_diario_aluno_turma_dia)
--    Preserva o registro do aluno 'sobrevivente' (4211504f...) se ambos existirem para a mesma turma e dia.
DELETE FROM public.diario
WHERE id_aluno = 'e893540e-19d1-4db5-ac6b-f3a175ef0c4b' -- Duplicado
AND EXISTS (
    SELECT 1 FROM public.diario d2
    WHERE d2.id_aluno = '4211504f-fa89-4b04-ba27-b4eed3af78e8' -- Sobrevivente
    AND d2.id_turma = public.diario.id_turma
    AND d2.data = public.diario.data
);

-- 2. Atualiza os registros restantes do aluno duplicado para o aluno sobrevivente
UPDATE public.diario
SET id_aluno = '4211504f-fa89-4b04-ba27-b4eed3af78e8' -- Sobrevivente
WHERE id_aluno = 'e893540e-19d1-4db5-ac6b-f3a175ef0c4b'; -- Duplicado
