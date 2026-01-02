CREATE OR REPLACE FUNCTION public.salvar_respostas_usuario_v3(
    p_id_usuario uuid,
    p_turma_id uuid, -- Novo parâmetro necessário para saber o contexto da candidatura
    p_respostas jsonb,
    p_user_expandido_id uuid DEFAULT NULL)
    RETURNS jsonb
    LANGUAGE plpgsql
AS $BODY$
DECLARE
    v_user_expandido_id uuid;
    v_item record;
    v_escopo_pergunta escopo_processo;
    v_id_turma_final uuid;
BEGIN
    -- 1. Resolver user_expandido_id (Padrão da sua arquitetura)
    IF p_user_expandido_id IS NOT NULL THEN
        v_user_expandido_id := p_user_expandido_id;
    ELSIF p_id_usuario IS NOT NULL THEN
        SELECT ue.id INTO v_user_expandido_id FROM public.user_expandido ue WHERE ue.user_id = p_id_usuario LIMIT 1;
    END IF;

    IF v_user_expandido_id IS NULL THEN
        RETURN jsonb_build_object('sucesso', false, 'mensagem', 'Usuário não encontrado.');
    END IF;

    -- 2. Loop pelas respostas para tratar cada escopo individualmente
    FOR v_item IN 
        SELECT 
            (r->>'id_pergunta')::uuid as id_pergunta,
            r->>'resposta' as resposta,
            NULLIF(r->>'nome_arquivo_original', '') as arquivo_original
        FROM jsonb_array_elements(p_respostas) r
    LOOP
        -- Descobre o escopo configurado para esta pergunta
        -- Se houver mais de um escopo para a mesma pergunta, priorizamos 'turma'
        SELECT escopo INTO v_escopo_pergunta 
        FROM public.processo_documentos_obrigatorios 
        WHERE id_pergunta = v_item.id_pergunta 
        ORDER BY (CASE WHEN escopo = 'turma' THEN 1 ELSE 2 END) ASC
        LIMIT 1;

        -- Lógica de decisão de Turma:
        -- Se for escopo TURMA, grava o ID da turma atual.
        -- Se for AREA ou qualquer outro, grava NULL (global).
        IF v_escopo_pergunta = 'turma' THEN
            v_id_turma_final := p_turma_id;
        ELSE
            v_id_turma_final := NULL;
        END IF;

        -- 3. UPSERT considerando a semântica do id_turma
        INSERT INTO public.respostas (
            user_expandido_id,
            id_usuario,
            id_pergunta,
            id_turma,
            resposta,
            arquivo_original,
            tipo_resposta,
            criado_em,
            atualizado_em
        )
        VALUES (
            v_user_expandido_id,
            p_id_usuario,
            v_item.id_pergunta,
            v_id_turma_final,
            v_item.resposta,
            v_item.arquivo_original,
            'texto',
            NOW(),
            NULL
        )
        ON CONFLICT (user_expandido_id, id_pergunta) WHERE id_turma IS NULL 
            DO UPDATE SET 
                resposta = EXCLUDED.resposta,
                arquivo_original = EXCLUDED.arquivo_original,
                atualizado_em = NOW()
        ON CONFLICT (user_expandido_id, id_pergunta, id_turma) WHERE id_turma IS NOT NULL
            DO UPDATE SET 
                resposta = EXCLUDED.resposta,
                arquivo_original = EXCLUDED.arquivo_original,
                atualizado_em = NOW();
    END LOOP;

    RETURN jsonb_build_object('sucesso', true, 'mensagem', 'Respostas processadas com sucesso respeitando os escopos.');
END;
$BODY$;