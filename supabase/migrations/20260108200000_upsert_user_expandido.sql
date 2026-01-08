CREATE OR REPLACE FUNCTION public.nxt_upsert_user_expandido(
    p_user_id uuid,
    p_nome text,
    p_sobrenome text,
    p_email text,
    p_papel_id uuid DEFAULT 'd19ba89e-9a15-4194-929a-db47695fb2be'
)
RETURNS jsonb
LANGUAGE plpgsql
AS $function$
DECLARE
    v_user_expandido_id uuid;
    v_result jsonb;
BEGIN
    -- Fazer upsert do usuário expandido
    INSERT INTO public.user_expandido (
        user_id,
        nome,
        sobrenome,
        email,
        papel_id,
        onboarding,
        status
    ) VALUES (
        p_user_id,
        p_nome,
        p_sobrenome,
        p_email,
        p_papel_id,
        true,
        true
    )
    ON CONFLICT (email) DO UPDATE SET
        nome = p_nome,
        sobrenome = p_sobrenome,
        papel_id = p_papel_id,
        status = true
    RETURNING id INTO v_user_expandido_id;

    -- Retornar resultado
    SELECT jsonb_build_object(
        'success', true,
        'user_expandido_id', v_user_expandido_id,
        'message', 'Usuário criado ou atualizado com sucesso'
    ) INTO v_result;

    RETURN v_result;
END;
$function$;

ALTER FUNCTION public.nxt_upsert_user_expandido(uuid, text, text, text, uuid) OWNER TO postgres;

GRANT ALL ON FUNCTION public.nxt_upsert_user_expandido(uuid, text, text, text, uuid) TO postgres;
GRANT ALL ON FUNCTION public.nxt_upsert_user_expandido(uuid, text, text, text, uuid) TO anon;
GRANT ALL ON FUNCTION public.nxt_upsert_user_expandido(uuid, text, text, text, uuid) TO authenticated;
GRANT ALL ON FUNCTION public.nxt_upsert_user_expandido(uuid, text, text, text, uuid) TO service_role;
