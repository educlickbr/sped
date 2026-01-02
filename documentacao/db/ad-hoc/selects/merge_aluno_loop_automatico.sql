DO $$ 
DECLARE
    r_email RECORD;
    r_survivor RECORD;
    r_duplicate RECORD;
    v_total_merged INTEGER := 0;
BEGIN
    -- Loop para cada email duplicado (case insensitive)
    FOR r_email IN 
        SELECT LOWER(email) as email_clean 
        FROM public.user_expandido 
        WHERE email IS NOT NULL 
        GROUP BY LOWER(email) 
        HAVING COUNT(*) > 1
    LOOP
        RAISE NOTICE 'Processando duplicatas para email: %', r_email.email_clean;

        -- 1. Identificar o "Sobrevivente"
        SELECT * INTO r_survivor
        FROM public.user_expandido
        WHERE LOWER(email) = r_email.email_clean
        ORDER BY 
            user_id IS NOT NULL DESC,      -- Prioriza quem tem user_id (TRUE > FALSE)
            (email = r_email.email_clean) DESC, -- Prioriza quem tem email igual à chave lowercase
            id ASC                         -- Desempate pelo ID
        LIMIT 1;

        RAISE NOTICE '  -> Sobrevivente: ID=% | Email=% | UserID=%', r_survivor.id, r_survivor.email, r_survivor.user_id;

        -- 2. Identificar e processar os "Duplicados" (todos exceto o sobrevivente)
        FOR r_duplicate IN 
            SELECT * 
            FROM public.user_expandido 
            WHERE LOWER(email) = r_email.email_clean 
            AND id != r_survivor.id
        LOOP
            RAISE NOTICE '    -> Mesclando Duplicado: ID=% | Email=%', r_duplicate.id, r_duplicate.email;

            -- A. Tabela matriculas
            DELETE FROM public.matriculas
            WHERE id_aluno = r_duplicate.id
            AND EXISTS (
                SELECT 1 FROM public.matriculas m2
                WHERE m2.id_aluno = r_survivor.id
                AND m2.id_turma = public.matriculas.id_turma
            );
            UPDATE public.matriculas SET id_aluno = r_survivor.id WHERE id_aluno = r_duplicate.id;


            -- B. Tabela diario
            DELETE FROM public.diario
            WHERE id_aluno = r_duplicate.id
            AND EXISTS (
                SELECT 1 FROM public.diario d2
                WHERE d2.id_aluno = r_survivor.id
                AND d2.id_turma = public.diario.id_turma
                AND d2.data = public.diario.data
            );
            UPDATE public.diario SET id_aluno = r_survivor.id WHERE id_aluno = r_duplicate.id;


            -- C. Tabela ra_alunos
            IF EXISTS (SELECT 1 FROM public.ra_alunos WHERE id_aluno = r_survivor.id) THEN
                DELETE FROM public.ra_alunos WHERE id_aluno = r_duplicate.id;
            ELSE
                UPDATE public.ra_alunos SET id_aluno = r_survivor.id WHERE id_aluno = r_duplicate.id;
            END IF;


            -- D. Tabela processos
            -- Se o sobrevivente já tem um processo para a mesma turma, removemos o do duplicado.
            -- (Assumindo que processos duplicados para a mesma turma não devem existir/são redundantes)
            DELETE FROM public.processos
            WHERE user_expandido_id = r_duplicate.id
            AND EXISTS (
                SELECT 1 FROM public.processos p2
                WHERE p2.user_expandido_id = r_survivor.id
                AND p2.turma_id = public.processos.turma_id
            );
            UPDATE public.processos SET user_expandido_id = r_survivor.id WHERE user_expandido_id = r_duplicate.id;
            -- Atualiza modificado_por
            UPDATE public.processos SET modificado_por = r_survivor.id WHERE modificado_por = r_duplicate.id;


            -- E. Tabela respostas
            -- Conflito: user_expandido_id + id_pergunta (respostas_unica_por_user_expandido_pergunta)
            DELETE FROM public.respostas
            WHERE user_expandido_id = r_duplicate.id
            AND EXISTS (
                SELECT 1 FROM public.respostas r2
                WHERE r2.user_expandido_id = r_survivor.id
                AND r2.id_pergunta = public.respostas.id_pergunta
            );
            UPDATE public.respostas SET user_expandido_id = r_survivor.id WHERE user_expandido_id = r_duplicate.id;
            UPDATE public.respostas SET aprovado_por = r_survivor.id WHERE aprovado_por = r_duplicate.id;


            -- F. Tabela respostas_perguntas_avaliacao_processos
            DELETE FROM public.respostas_perguntas_avaliacao_processos
            WHERE id_user = r_duplicate.id
            AND EXISTS (
                SELECT 1 FROM public.respostas_perguntas_avaliacao_processos r2
                WHERE r2.id_user = r_survivor.id
                AND r2.id_pergunta_processo = public.respostas_perguntas_avaliacao_processos.id_pergunta_processo
                AND r2.id_processo = public.respostas_perguntas_avaliacao_processos.id_processo
            );
            UPDATE public.respostas_perguntas_avaliacao_processos SET id_user = r_survivor.id WHERE id_user = r_duplicate.id;
            UPDATE public.respostas_perguntas_avaliacao_processos SET criado_por = r_survivor.id WHERE criado_por = r_duplicate.id;


            -- G. Tabela produto_reservas
            UPDATE public.produto_reservas SET id_usuario = r_survivor.id WHERE id_usuario = r_duplicate.id;
            UPDATE public.produto_reservas SET usuario_devolveu = r_survivor.id WHERE usuario_devolveu = r_duplicate.id;


            -- H. Remover usuário duplicado
            -- Se ainda houver FKs não tratadas, isso falhará.
            DELETE FROM public.user_expandido
            WHERE id = r_duplicate.id;

            v_total_merged := v_total_merged + 1;
        END LOOP;

    END LOOP;

    RAISE NOTICE 'Processo finalizado. Total de usuários mesclados/removidos: %', v_total_merged;
END $$;
