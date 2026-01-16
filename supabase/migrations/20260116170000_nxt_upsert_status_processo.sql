CREATE OR REPLACE FUNCTION public.nxt_upsert_status_processo(p_id_processo uuid, p_status text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_processo RECORD;
BEGIN
    -- 1. Verificar se o processo existe
    SELECT * INTO v_processo FROM public.processos WHERE id = p_id_processo;
    
    IF v_processo IS NULL THEN
        RETURN jsonb_build_object(
            'success', false, 
            'message', 'Processo não encontrado.'
        );
    END IF;

    -- 2. Atualizar o status
    UPDATE public.processos
    SET status = p_status,
        modificado_em = now()
    WHERE id = p_id_processo;

    RETURN jsonb_build_object(
        'success', true, 
        'message', 'Status atualizado para: ' || COALESCE(p_status, 'Resetado'),
        'id_processo', p_id_processo,
        'novo_status', p_status
    );
END;
$function$;
