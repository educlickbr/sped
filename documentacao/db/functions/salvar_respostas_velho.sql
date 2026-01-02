
DROP FUNCTION IF EXISTS public.salvar_respostas_usuario(uuid, jsonb, uuid);
CREATE OR REPLACE FUNCTION public.salvar_respostas_usuario(

    p_id_usuario uuid,

    p_respostas jsonb,

    p_user_expandido_id uuid DEFAULT NULL::uuid)

    RETURNS void

    LANGUAGE plpgsql

    COST 100

    VOLATILE PARALLEL UNSAFE

AS $BODY$

DECLARE

    v_user_expandido_id uuid;

BEGIN

    -------------------------------------------------------------------

    -- 1. Resolver user_expandido_id

    -------------------------------------------------------------------



    -- Caso 1: vier user_expandido_id explícito

    IF p_user_expandido_id IS NOT NULL THEN

        v_user_expandido_id := p_user_expandido_id;



    -- Caso 2: usar p_id_usuario (auth.users)

    ELSIF p_id_usuario IS NOT NULL THEN

        SELECT ue.id

        INTO v_user_expandido_id

        FROM public.user_expandido ue

        WHERE ue.user_id = p_id_usuario

        LIMIT 1;



        IF v_user_expandido_id IS NULL THEN

            RAISE EXCEPTION 'Usuário expandido não encontrado para o p_id_usuario informado.';

        END IF;



    ELSE

        RAISE EXCEPTION 'É necessário informar p_id_usuario ou p_user_expandido_id.';

    END IF;



    -------------------------------------------------------------------

    -- 2. Transformação dos dados

    -------------------------------------------------------------------

    WITH dados AS (

        SELECT

            v_user_expandido_id                  AS user_expandido_id,

            p_id_usuario                         AS id_usuario,

            (r.id_pergunta)::uuid               AS id_pergunta,

            r.resposta                          AS resposta,

            NULLIF(r.nome_arquivo_original, '') AS arquivo_original

        FROM jsonb_to_recordset(p_respostas) AS r(

            id_pergunta text,

            resposta text,

            nome_arquivo_original text

        )

    ),

    com_tipo AS (

        SELECT

            d.user_expandido_id,

            d.id_usuario,

            d.id_pergunta,

            d.resposta,

            d.arquivo_original,

            COALESCE(pg.tipo, 'texto') AS tipo_resposta

        FROM dados d

        LEFT JOIN public.perguntas pg ON pg.id = d.id_pergunta

    )

    -------------------------------------------------------------------

    -- 3. UPSERT

    -------------------------------------------------------------------

    INSERT INTO public.respostas (

        user_expandido_id,

        id_usuario,

        id_pergunta,

        resposta,

        arquivo_original,

        tipo_resposta,

        criado_em,

        atualizado_em

    )

    SELECT

        user_expandido_id,

        id_usuario,

        id_pergunta,

        resposta,

        arquivo_original,

        tipo_resposta,

        NOW(),

        NULL

    FROM com_tipo

    ON CONFLICT (user_expandido_id, id_pergunta) DO UPDATE

    SET resposta         = EXCLUDED.resposta,

        arquivo_original = EXCLUDED.arquivo_original,

        tipo_resposta    = EXCLUDED.tipo_resposta,

        atualizado_em    = NOW(),

        id_usuario       = EXCLUDED.id_usuario;

END;

$BODY$;






