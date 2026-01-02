CREATE OR REPLACE FUNCTION public.email_threads_upsert(
    p_assunto text,
    p_mensagem text,
    p_escopo text,
    p_id_user_origem uuid, -- Obrigatório (quem manda)
    p_ano_semestre text DEFAULT NULL,
    p_status_thread text DEFAULT 'pendente',
    p_id_turma uuid DEFAULT NULL,
    p_id_user_destino uuid DEFAULT NULL,
    p_filtro_area text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $BODY$
DECLARE
    v_existing_id uuid;
    v_new_id uuid;
BEGIN
    -- 1. DESINFECÇÃO / VALIDAÇÃO BÁSICA
    -- (Pode adicionar validações aqui se necessário, ex: id_turma required se escopo = turma)

    -- 2. VERIFICAÇÃO DE DUPLICIDADE (IDEMPOTÊNCIA)
    
    -- Case 1: Scope 'user'
    IF p_escopo = 'user' THEN
        SELECT id INTO v_existing_id
        FROM public.email_threads
        WHERE escopo = 'user'
          AND assunto = p_assunto
          AND mensagem = p_mensagem
          AND id_user_destino = p_id_user_destino
          AND created_at > now() - interval '1 hour' -- Opcional: Janela de tempo para considerar duplicado? 
          -- O usuário pediu "se existe... ignora". Sem janela de tempo, nunca mais poderá mandar o mesmo email para a mesma pessoa.
          -- Vou assumir uma janela de segurança (ex: 24h) ou verificação absoluta se for crítica. 
          -- Pelo pedido "verificar se existe", farei absoluto para o teste, mas alertarei sobre janela de tempo.
        LIMIT 1;

    -- Case 2: Scope 'turma'
    ELSIF p_escopo = 'turma' THEN
        SELECT id INTO v_existing_id
        FROM public.email_threads
        WHERE escopo = 'turma'
          AND assunto = p_assunto
          AND mensagem = p_mensagem
          AND id_turma = p_id_turma
        LIMIT 1;

    -- Case 3: Scope 'area'
    ELSIF p_escopo = 'area' THEN
        SELECT id INTO v_existing_id
        FROM public.email_threads
        WHERE escopo = 'area'
          AND assunto = p_assunto
          AND mensagem = p_mensagem
          -- Comparação de filtros e área. 
          -- Assumindo que para 'area', o filtro_area e ano_semestre definem a unicidade junto com o conteúdo.
          AND COALESCE(filtro_area, '') = COALESCE(p_filtro_area, '')
          AND COALESCE(ano_semestre, '') = COALESCE(p_ano_semestre, '')
        LIMIT 1;
    END IF;

    -- 3. AÇÃO: RETORNAR EXISTENTE OU INSERIR NOVO
    
    IF v_existing_id IS NOT NULL THEN
        RETURN jsonb_build_object(
            'status', 'ignorado',
            'mensagem', 'Thread duplicada detectada. Nenhuma ação realizada.',
            'id', v_existing_id
        );
    ELSE
        INSERT INTO public.email_threads (
            assunto,
            mensagem,
            escopo,
            ano_semestre,
            status_thread,
            id_turma,
            id_user_origem,
            id_user_destino,
            filtro_area
        ) VALUES (
            p_assunto,
            p_mensagem,
            p_escopo,
            p_ano_semestre,
            p_status_thread, -- Geralmente 'pendente'
            p_id_turma,
            p_id_user_origem,
            p_id_user_destino,
            p_filtro_area
        )
        RETURNING id INTO v_new_id;

        RETURN jsonb_build_object(
            'status', 'sucesso',
            'mensagem', 'Nova thread criada.',
            'id', v_new_id
        );
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('status', 'erro', 'mensagem', SQLERRM);
END;
$BODY$;
