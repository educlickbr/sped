-- Function to fetch expanded user data and fallbacks from answers
DROP FUNCTION IF EXISTS public.get_user_expandido;
CREATE OR REPLACE FUNCTION public.get_user_expandido(p_auth_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result jsonb;
    v_ux_id uuid;
    v_foto_fallback text;
    v_eixo text;
BEGIN
    -- 1. Fetch from user_expandido
    SELECT 
        jsonb_build_object(
            'user_expandido_id', id,
            'nome', nome,
            'sobrenome', sobrenome,
            'email', email,
            'imagem_user', imagem_user
        ), id
    INTO v_result, v_ux_id
    FROM public.user_expandido
    WHERE user_id = p_auth_id;

    -- If no record in user_expandido, start with empty object
    IF v_result IS NULL THEN
        v_result := jsonb_build_object('user_expandido_id', NULL, 'nome', NULL, 'sobrenome', NULL, 'email', NULL, 'imagem_user', NULL);
    END IF;

    -- 2. Fetch from respostas as fallback/extra
    -- sua_foto: c95e476a-c4dc-4520-badd-d7392b0aeab7
    -- eixo: 0c05fac6-6cf1-41b0-985d-931fff2a59bb
    
    SELECT resposta INTO v_foto_fallback
    FROM public.respostas
    WHERE (user_expandido_id = v_ux_id OR id_usuario = p_auth_id)
      AND id_pergunta = 'c95e476a-c4dc-4520-badd-d7392b0aeab7'
    ORDER BY criado_em DESC LIMIT 1;

    SELECT resposta INTO v_eixo
    FROM public.respostas
    WHERE (user_expandido_id = v_ux_id OR id_usuario = p_auth_id)
      AND id_pergunta = '0c05fac6-6cf1-41b0-985d-931fff2a59bb'
    ORDER BY criado_em DESC LIMIT 1;

    -- Merge existing result with fallbacks
    RETURN v_result || jsonb_build_object(
        'imagem_user', COALESCE(v_result->>'imagem_user', v_foto_fallback),
        'eixo', v_eixo
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_expandido(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_expandido(uuid) TO service_role;
