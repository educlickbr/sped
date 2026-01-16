CREATE OR REPLACE FUNCTION public.nxt_upsert_status_matricula(p_id_matricula uuid, p_status text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_result jsonb;
    v_new_status status_matricula;
BEGIN
    -- Tenta converter o status recebido para o enum
    BEGIN
        v_new_status := p_status::status_matricula;
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Status inválido: %', p_status;
    END;

    UPDATE public.matriculas
    SET 
        status = v_new_status,
        atualizado_em = now()
    WHERE id = p_id_matricula
    RETURNING jsonb_build_object(
        'id', id,
        'status', status,
        'atualizado_em', atualizado_em
    ) INTO v_result;

    IF v_result IS NULL THEN
        RAISE EXCEPTION 'Matrícula não encontrada: %', p_id_matricula;
    END IF;

    RETURN v_result;
END;
$function$;
