CREATE OR REPLACE FUNCTION public.criar_processo_unico(p_id_user_expandido uuid, p_id_candidatura uuid, p_tipo_candidatura tipo_candidatura, p_tipo_processo tipo_processo)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_user_id uuid;
    v_papel_id uuid;
    v_exist uuid;
    v_id_processo uuid;
BEGIN
    --------------------------------------------------------------------
    -- 1) Número de vezes que aluno clica → idempotência total
    --------------------------------------------------------------------
    SELECT id INTO v_exist
    FROM public.processos
    WHERE user_expandido_id = p_id_user_expandido
      AND turma_id = p_id_candidatura   -- HOJE é turma
      AND tipo_processo = p_tipo_processo
      AND tipo_candidatura = p_tipo_candidatura
    LIMIT 1;

    IF v_exist IS NOT NULL THEN
        RETURN jsonb_build_object(
            'ok', true,
            'acao', 'ignorado',
            'mensagem', 'processo já existia',
            'id_processo', v_exist
        );
    END IF;

    --------------------------------------------------------------------
    -- 2) Buscar user_id (auth) no user_expandido
    --------------------------------------------------------------------
    SELECT user_id INTO v_user_id
    FROM public.user_expandido
    WHERE id = p_id_user_expandido;

    --------------------------------------------------------------------
    -- 3) Buscar papel do usuário
    --------------------------------------------------------------------
    SELECT papel_id INTO v_papel_id
    FROM public.papeis_user_auth
    WHERE user_id = v_user_id
    LIMIT 1;

    --------------------------------------------------------------------
    -- 4) Criar processo
    --------------------------------------------------------------------
    INSERT INTO public.processos (
        user_id,
        user_expandido_id,
        turma_id,              -- HOJE é turma, futuro mudamos aqui
        tipo_candidatura,
        tipo_processo,
        papel_user,
        status               -- deixa NULL para o sistema definir depois
    )
    VALUES (
        v_user_id,
        p_id_user_expandido,
        p_id_candidatura,
        p_tipo_candidatura,
        p_tipo_processo,
        v_papel_id,
        NULL
    )
    RETURNING id INTO v_id_processo;

    --------------------------------------------------------------------
    -- 5) Retorno final
    --------------------------------------------------------------------
    RETURN jsonb_build_object(
        'ok', true,
        'acao', 'criado',
        'id_processo', v_id_processo
    );
END;
$function$
