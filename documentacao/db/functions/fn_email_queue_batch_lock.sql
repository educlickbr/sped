CREATE OR REPLACE FUNCTION public.fn_email_queue_batch_lock(
    p_thread_id uuid,
    p_batch_size int DEFAULT 10
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_batch_data jsonb;
BEGIN
    -- 1. Tenta travar N itens que estão 'aguardando'
    -- Usa FOR UPDATE SKIP LOCKED para evitar contenção se houver múltiplos processadores (embora aqui seja sequencial)
    
    WITH itens_selecionados AS (
        SELECT id
        FROM public.email_queue
        WHERE id_thread = p_thread_id
          AND status_fila = 'aguardando'
        ORDER BY created_at ASC
        LIMIT p_batch_size
        FOR UPDATE SKIP LOCKED
    ),
    itens_atualizados AS (
        UPDATE public.email_queue
        SET 
            status_fila = 'enviando',
            -- data_envio = now(), -- Data envio é quando realmente for para o Power Automate? Ou quando sai da fila? Vamos deixar NULL ou setar agora. O padrão anterior era NULL.
            updated_at = now()
        WHERE id IN (SELECT id FROM itens_selecionados)
        RETURNING id, email_destino, mensagem, assunto
    )
    SELECT 
        jsonb_agg(to_jsonb(itens_atualizados.*))
    INTO v_batch_data
    FROM itens_atualizados;

    -- 2. Trata caso de array vazio
    IF v_batch_data IS NULL THEN
        RETURN jsonb_build_object(
            'batch_count', 0,
            'batch_data', '[]'::jsonb
        );
    END IF;

    -- 3. Atualiza o status da Thread para 'enviando' (Gatilho da Edge Function)
    -- IMPORTANTE: Atualiza updated_at para garantir que o Supabase detecte evento,
    -- mesmo que o status já fosse 'enviando'.
    UPDATE public.email_threads
    SET 
        status_thread = 'enviando',
        updated_at = now()
    WHERE id = p_thread_id;

    RETURN jsonb_build_object(
        'batch_count', jsonb_array_length(v_batch_data),
        'batch_data', v_batch_data
    );
END;
$$;
