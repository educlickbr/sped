DO $$ 
DECLARE
    -- Mude aqui os IDs
    v_id_duplicado UUID := '778b91eb-2f1a-4a28-b3b5-8c8d2d8928c2';
    v_id_sobrevivente UUID := '51c3ef93-a8e7-4265-8201-19a2474620e1';
BEGIN
    -- 1. Tabela matricular
    -- Remove registros do aluno duplicado que causariam conflito de unicidade (matriculas_id_aluno_id_turma_key)
    -- Preserva o registro do aluno 'sobrevivente' se ambos existirem para a mesma turma.
    DELETE FROM public.matriculas
    WHERE id_aluno = v_id_duplicado
    AND EXISTS (
        SELECT 1 FROM public.matriculas m2
        WHERE m2.id_aluno = v_id_sobrevivente
        AND m2.id_turma = public.matriculas.id_turma
    );

    -- Atualiza os registros restantes do aluno duplicado para o aluno sobrevivente
    UPDATE public.matriculas
    SET id_aluno = v_id_sobrevivente
    WHERE id_aluno = v_id_duplicado;

    RAISE NOTICE 'Tabela matriculas atualizada.';

    -- 2. Tabela diario
    -- Remove registros do aluno duplicado que causariam conflito de unicidade (uq_diario_aluno_turma_dia)
    -- Preserva o registro do aluno 'sobrevivente' se ambos existirem para a mesma turma e dia.
    DELETE FROM public.diario
    WHERE id_aluno = v_id_duplicado
    AND EXISTS (
        SELECT 1 FROM public.diario d2
        WHERE d2.id_aluno = v_id_sobrevivente
        AND d2.id_turma = public.diario.id_turma
        AND d2.data = public.diario.data
    );

    -- Atualiza os registros restantes do aluno duplicado para o aluno sobrevivente
    UPDATE public.diario
    SET id_aluno = v_id_sobrevivente
    WHERE id_aluno = v_id_duplicado;
    
    RAISE NOTICE 'Tabela diario atualizada.';

    -- 3. Deletar usuário duplicado
    -- ATENÇÃO: Se existirem outras tabelas referenciando este ID (financeiro, respostas, etc.), o comando abaixo falhará.
    DELETE FROM public.user_expandido
    WHERE id = v_id_duplicado;

    RAISE NOTICE 'Usuário duplicado removido (se não houve erro de FK).';

END $$;
