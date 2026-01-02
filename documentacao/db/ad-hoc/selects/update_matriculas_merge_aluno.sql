-- 1. Remove registros do aluno duplicado que causariam conflito de unicidade (matriculas_id_aluno_id_turma_key)
--    Preserva o registro do aluno 'sobrevivente' se ambos existirem para a mesma turma.
DELETE FROM public.matriculas
WHERE id_aluno = '82f0b4bc-010f-405a-8e78-53d602500529' -- Duplicado
AND EXISTS (
    SELECT 1 FROM public.matriculas m2
    WHERE m2.id_aluno = 'I82f0b4bc-010f-405a-8e78-53d602500529' -- Sobrevivente
    AND m2.id_turma = public.matriculas.id_turma
);

-- 2. Atualiza os registros restantes do aluno duplicado para o aluno sobrevivente
UPDATE public.matriculas
SET id_aluno = '82f0b4bc-010f-405a-8e78-53d602500529' -- Sobrevivente
WHERE id_aluno = '82f0b4bc-010f-405a-8e78-53d602500529'; -- Duplicado
