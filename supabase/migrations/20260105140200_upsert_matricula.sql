CREATE OR REPLACE FUNCTION public.upsert_matricula(
    p_id_turma uuid,
    p_id_user uuid
)
RETURNS void
LANGUAGE plpgsql
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
        'Ativa', -- Conforme solicitado e verificado no schema
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

ALTER FUNCTION public.upsert_matricula(uuid, uuid) OWNER TO postgres;

GRANT ALL ON FUNCTION public.upsert_matricula(uuid, uuid) TO postgres;
GRANT ALL ON FUNCTION public.upsert_matricula(uuid, uuid) TO anon;
GRANT ALL ON FUNCTION public.upsert_matricula(uuid, uuid) TO authenticated;
GRANT ALL ON FUNCTION public.upsert_matricula(uuid, uuid) TO service_role;
