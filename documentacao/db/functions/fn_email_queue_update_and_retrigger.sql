drop function public.fn_email_queue_update_and_retrigger;
create or replace function public.fn_email_queue_update_and_retrigger(
    p_thread_id uuid,
    p_lote_enviado_ids uuid[],   -- IDs que foram processados com sucesso
    p_lote_falha_ids uuid[]      -- IDs que falharam no envio
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
    v_total_atualizado int;
    v_aguardando_count int;
    v_lock_result jsonb;
    v_novo_thread_status varchar;
begin

    -- 1. ATUALIZAR ITENS DA QUEUE (SUCESSO)
    with sucesso as (
        update email_queue
        set status_fila = 'enviado', updated_at = now()
        where id = any(p_lote_enviado_ids)
        returning id
    )
    select count(id) into v_total_atualizado from sucesso;

    -- 2. ATUALIZAR ITENS DA QUEUE (FALHA)
    with falha as (
        update email_queue
        set status_fila = 'erro', updated_at = now()
        where id = any(p_lote_falha_ids)
        returning id
    )
    select v_total_atualizado + count(id) into v_total_atualizado from falha;

    -- 3. RESET DE SINALIZAÇÃO (CRÍTICO)
    -- Define status para 'processando' para garantir que a próxima mudança para 'enviando'
    -- seja detectada como uma ALTERAÇÃO de estado (old != new) pelo trigger do Supabase.
    update email_threads
    set status_thread = 'processando', updated_at = now()
    where id = p_thread_id;

    -- 4. VERIFICAÇÃO E RE-DISPARO
    
    -- Conta quantos itens AINDA PRECISAM ser processados
    select count(id)
    into v_aguardando_count
    from email_queue
    where id_thread = p_thread_id
      and status_fila = 'aguardando';

    if v_aguardando_count > 0 then
        -- RE-DISPARO: Chama a função de bloqueio.
        -- Esta função vai alterar o status_thread de volta para 'enviando'.
        -- Transição: processando -> enviando (Gatilho OK!)
        select public.fn_email_queue_batch_lock(p_thread_id, 10) into v_lock_result;
        v_novo_thread_status := 'enviando';

    else
        -- FINALIZAÇÃO: Não há mais itens.
        -- Transição: processando -> completa
        update email_threads
        set status_thread = 'completa', updated_at = now()
        where id = p_thread_id
        returning status_thread into v_novo_thread_status;
        
        v_lock_result := null;
    end if;

    -- 5. RETORNO
    return jsonb_build_object(
        'status', 'sucesso',
        'mensagem', 'Ciclo finalizado.',
        'total_atualizado', v_total_atualizado,
        'aguardando_restantes', v_aguardando_count,
        'thread_status_final', v_novo_thread_status,
        'lock_attempt', coalesce(v_lock_result, 'null'::jsonb)
    );

exception
    when others then
        return jsonb_build_object('status', 'erro', 'mensagem', SQLERRM);
end;
$$;