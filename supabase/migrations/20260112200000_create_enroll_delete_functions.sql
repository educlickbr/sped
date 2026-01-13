-- Function to enroll a student (matricula)
CREATE OR REPLACE FUNCTION public.nxt_upsert_matricula(p_id_turma uuid, p_id_user uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    INSERT INTO public.matriculas (
        id_turma,
        id_aluno,
        status,
        declaracao_matricula,
        rematricula,
        criado_em,
        atualizado_em
    ) VALUES (
        p_id_turma,
        p_id_user,
        'Ativa',
        FALSE,
        FALSE,
        now(),
        now()
    )
    ON CONFLICT (id_aluno, id_turma)
    DO UPDATE SET
        status = 'Ativa',
        rematricula = FALSE,
        declaracao_matricula = FALSE,
        atualizado_em = now();
END;
$function$;

-- Function to delete a selection process (soft or hard delete depending on requirement, here hard delete of process only)
CREATE OR REPLACE FUNCTION public.nxt_delete_inscricao_processo(p_processo_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Deletar o registro do processo seletivo pelo ID
    -- As respostas associadas não são deletadas (exigência do usuário)
    DELETE FROM public.processos
    WHERE id = p_processo_id;

    RAISE NOTICE 'Processo seletivo removido. ID: %', p_processo_id;
END;
$function$;
