CREATE OR REPLACE FUNCTION public.upsert_professor_turma_atribuicao(
    p_user_id uuid, -- ID do Professor (user_expandido.id)
    p_turmas uuid[] -- Array de IDs de Turmas
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $BODY$
DECLARE
    v_auth_id uuid;
    v_executor_id uuid;
    v_turma_id uuid;
    v_inserted_count int := 0;
    v_updated_count int := 0;
BEGIN
    -- 1. Obter o auth_id do professor (para redundância/RLS)
    SELECT user_id INTO v_auth_id
    FROM public.user_expandido
    WHERE id = p_user_id;

    IF v_auth_id IS NULL THEN
        RETURN jsonb_build_object(
            'status', 'erro',
            'mensagem', 'Professor não encontrado em user_expandido.'
        );
    END IF;

    -- 2. Obter o ID do executor (quem está rodando a função) para auditoria (criado_por/modificado_por)
    SELECT id INTO v_executor_id
    FROM public.user_expandido
    WHERE user_id = auth.uid();
    
    -- Se quem executa não tem user_expandido (ex: service role ou erro), v_executor_id será NULL.
    -- Opcional: tratar esse caso ou deixar NULL.

    -- 3. Loop pelas turmas
    IF p_turmas IS NOT NULL THEN
        FOREACH v_turma_id IN ARRAY p_turmas
        LOOP
            -- Tenta inserir. Se houver conflito (constraint única), faz update (ou nada).
            -- Como a constraint unique (user_id, id_turmas) foi criada, podemos usar ON CONFLICT.
            -- Caso a constraint não exista no momento da execução, esse codigo falhará se houver duplicidade.
            -- Mas o passo a passo indicou a criação da constraint.
            
            INSERT INTO public.professor_turma_atribuicao (
                user_id,
                id_turmas,
                status,
                avaliador,
                criado_por,
                criado_em,
                auth_id
            ) VALUES (
                p_user_id,
                v_turma_id,
                true,  -- Default status
                false, -- Default avaliador
                v_executor_id,
                timezone('utc'::text, now()),
                v_auth_id
            )
            ON CONFLICT (user_id, id_turmas) 
            DO UPDATE SET
                modificado_por = v_executor_id,
                modificado_em = timezone('utc'::text, now());
                -- Não atualizamos status ou avaliador no conflito para preservar configs manuais,
                -- a menos que seja requisito resetar. Assumo preservar.
            
            IF FOUND THEN
                 -- FOUND é setado true se insert ou update ocorreu com sucesso
                 -- Como não temos como distinguir facilmente insert de update no count simples sem xmax,
                 -- vamos apenas contar como processado.
                 v_inserted_count := v_inserted_count + 1;
            END IF;
            
        END LOOP;
    END IF;

    RETURN jsonb_build_object(
        'status', 'sucesso',
        'mensagem', 'Atribuições processadas.',
        'total_processado', v_inserted_count
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('status', 'erro', 'mensagem', SQLERRM);
END;
$BODY$;

ALTER FUNCTION public.upsert_professor_turma_atribuicao(uuid, uuid[])
    OWNER TO postgres;
