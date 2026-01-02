-- Bloco de Teste para a Thread 7777: Insere Thread Mestre Placeholder e 20 itens na Fila
DO $$
DECLARE
    -- ID da NOVA Thread de teste 
    v_thread_id constant uuid := '77777777-7777-7777-7777-777777777777';
    
    -- ID de usuário de teste (Para o FK em email_threads.id_user_origem)
    v_user_origem constant uuid := 'f69aafee-8285-4f79-8fd0-bd8c9795b43e';
    
    -- Email de destino de teste (Para o email_queue.email_destino)
    v_email_destino constant varchar := 'martineikmeier@gmail.com';
    
    v_total_inserido integer;
    v_lock_result jsonb;
BEGIN

    -- 1. GARANTIR A THREAD MESTRE (Com o ID de Usuário correto)
    RAISE NOTICE '1. Inserindo ou atualizando registro de Thread Mestre (ID: %)...', v_thread_id;
    
    -- Tenta inserir. Se já existir, apenas atualiza.
    INSERT INTO public.email_threads (
        id, assunto, mensagem, escopo, status_thread, id_user_origem, created_at, updated_at
    )
    VALUES (
        v_thread_id,
        'Teste de Fila 7777 - Assunto Base',
        'Esta é a mensagem de teste para a fila de emails 7777.',
        'user_teste',
        'pendente', -- Status inicial. O trigger ou a função abaixo vai mudar para 'enviando'.
        v_user_origem, 
        now(),
        now()
    )
    ON CONFLICT (id) DO UPDATE SET 
        updated_at = now(),
        id_user_origem = v_user_origem,
        status_thread = 'pendente'; 

    -- 2. INSERIR 20 REGISTROS NA FILA (Status: 'aguardando')
    RAISE NOTICE '2. Inserindo 20 registros na Fila de E-mails...';

    -- NOTA: Como alteramos o Trigger para disparar o lock automaticamente, 
    -- ao inserir na email_threads pode ser que o trigger dispare se usarmos INSERT normal na tabela pai? 
    -- Não, o trigger 'par_trg_fila_email' é na email_threads mesmo. 
    -- Mas nosso teste está fazendo INSERT manual na email_queue.
    -- O trigger original par_trg_fila_email popula a fila.
    -- Vamos SIMULAR o comportamento real: Não inserir na fila manualmente, deixar o trigger fazer isso?
    -- O script original inseria manualmente.
    -- Se inserirmos manualmente na fila, o trigger da thread (se existir) não vai saber.
    
    -- VAMOS MANTER O INSERT MANUAL PARA TESTE CONTROLADO, MAS TEMOS QUE CHAMAR O LOCK MANUALMENTE.
    
    INSERT INTO public.email_queue (
        id_thread, email_destino, assunto, mensagem, status_fila, tentativas, created_at, updated_at
    )
    SELECT
        v_thread_id,
        v_email_destino, 
        'Assunto 7777 Lote ' || s::text, 
        'Mensagem de teste ' || s::text || '. Enviado para ' || v_email_destino,
        'aguardando', 
        0,
        now() + (s * interval '1 millisecond'), 
        now()
    FROM generate_series(1, 20) s;

    -- 3. RESULTADO DA INSERÇÃO
    GET DIAGNOSTICS v_total_inserido = ROW_COUNT;
    RAISE NOTICE '3. Sucesso! % registros inseridos na email_queue.', v_total_inserido;

    -- 4. INICIAR O PRIMEIRO LOTE MANUALMENTE (KICKSTART)
    -- Isso simula o que o Trigger faria.
    RAISE NOTICE '4. Chamando fn_email_queue_batch_lock para iniciar o primeiro lote (10 itens)...';
    SELECT public.fn_email_queue_batch_lock(v_thread_id, 10) INTO v_lock_result;

    RAISE NOTICE '5. Resultado do Lock: %', v_lock_result;
    
END $$;