DROP FUNCTION IF EXISTS public.salvar_respostas_usuario_v2(uuid, jsonb, uuid);
CREATE OR REPLACE FUNCTION public.salvar_respostas_usuario_v2(
	p_id_usuario uuid,
	p_respostas jsonb,
	p_user_expandido_id uuid DEFAULT NULL)
    RETURNS jsonb
    LANGUAGE plpgsql
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    v_user_expandido_id uuid;
    v_resposta_invalida jsonb;
BEGIN
    -------------------------------------------------------------------
    -- 0. Validação de Entrada (NULL ou Vazio)
    -------------------------------------------------------------------
    -- Verifica se existe alguma resposta nula ou vazia no JSON recebido
    SELECT to_jsonb(r)
    INTO v_resposta_invalida
    FROM jsonb_to_recordset(p_respostas) AS r(id_pergunta text, resposta text)
    WHERE r.resposta IS NULL OR trim(r.resposta) = ''
    LIMIT 1;

    IF v_resposta_invalida IS NOT NULL THEN
        RETURN jsonb_build_object(
            'sucesso', false,
            'mensagem', 'Não é permitido salvar respostas vazias ou nulas.',
            'dado_invalido', v_resposta_invalida
        );
    END IF;

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
            RETURN jsonb_build_object(
                'sucesso', false,
                'mensagem', 'Usuário expandido não encontrado para o p_id_usuario informado.'
            );
        END IF;

    ELSE
        RETURN jsonb_build_object(
            'sucesso', false,
            'mensagem', 'É necessário informar p_id_usuario ou p_user_expandido_id.'
        );
    END IF;

    -------------------------------------------------------------------
    -- 2. Transformação e Persistência (com tratamento de erro)
    -------------------------------------------------------------------
    BEGIN
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

        -- Retorno de Sucesso
        RETURN jsonb_build_object(
            'sucesso', true,
            'mensagem', 'Respostas salvas com sucesso.'
        );

    EXCEPTION WHEN OTHERS THEN
        -- Retorno de Erro Genérico (capturando mensagem do banco)
        RETURN jsonb_build_object(
            'sucesso', false,
            'mensagem', 'Erro ao salvar respostas: ' || SQLERRM
        );
    END;
END;
$BODY$;

