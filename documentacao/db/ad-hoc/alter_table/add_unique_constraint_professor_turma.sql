ALTER TABLE public.professor_turma_atribuicao
    ADD CONSTRAINT professor_turma_atribuicao_user_turma_unique UNIQUE (user_id, id_turmas);
