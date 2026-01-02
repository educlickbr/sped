CREATE OR REPLACE FUNCTION public.get_users_por_papeis_paginado(
    p_pagina integer DEFAULT 1,
    p_limite integer DEFAULT 20,
    p_busca text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $BODY$
DECLARE
    v_result jsonb;
    v_papeis_ids uuid[] := ARRAY[
        'fbae2a34-8f84-464d-8f04-11e8f65443f9'::uuid, -- Analistas
        'e4a0f9c0-7612-4cf9-92c7-a6ab781dabf6'::uuid, -- Assistentes
        '65aaed43-f4cd-4b47-ac2d-aaab3a301c78'::uuid, -- Coordenadores
        '1ff10e30-3a2b-4a61-ba8c-0d74ba2cde6b'::uuid, -- Convidados
        '8f3d1cd3-75fd-4549-b4ea-2b2e1411c2ec'::uuid  -- Docentes
    ];
BEGIN
    WITH filtered_data AS (
        SELECT 
            u.*
        FROM public.user_expandido u
        LEFT JOIN auth.users au ON au.id = u.user_id
        WHERE u.papel_id = ANY(v_papeis_ids)
          AND (p_busca IS NULL OR (
               u.nome ILIKE '%' || p_busca || '%'
            OR u.sobrenome ILIKE '%' || p_busca || '%'
          ))
    ),
    total_count AS (
        SELECT count(*) AS qtd FROM filtered_data
    ),
    paginated_rows AS (
        SELECT 
            fd.*,
            au.created_at as auth_created_at
        FROM filtered_data fd
        LEFT JOIN auth.users au ON au.id = fd.user_id
        ORDER BY au.created_at DESC NULLS LAST
        LIMIT p_limite OFFSET (p_pagina - 1) * p_limite
    )
    SELECT jsonb_build_object(
        'qtd_itens', (SELECT qtd FROM total_count),
        'qtd_paginas', ceil((SELECT qtd FROM total_count)::numeric / GREATEST(p_limite, 1)),
        'itens', COALESCE(jsonb_agg(to_jsonb(pr.*) - 'auth_created_at'), '[]'::jsonb)
    )
    INTO v_result
    FROM paginated_rows pr;

    RETURN v_result;

EXCEPTION
    WHEN OTHERS THEN
         RETURN jsonb_build_object(
            'qtd_itens', 0,
            'qtd_paginas', 0,
            'itens', '[]'::jsonb,
            'erro', SQLERRM
         );
END;
$BODY$;

ALTER FUNCTION public.get_users_por_papeis_paginado(integer, integer, text)
    OWNER TO postgres;
