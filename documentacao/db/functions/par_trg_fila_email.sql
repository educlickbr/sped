CREATE OR REPLACE FUNCTION public.par_trg_fila_email()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100
AS $BODY$
DECLARE
    v_normalized_area text;
    v_lock_result jsonb;
BEGIN
    -- 1. Scope: 'user'
    IF NEW.escopo = 'user' THEN
        INSERT INTO public.email_queue (
            id_thread,
            email_destino,
            assunto,
            mensagem,
            status_fila,
            tentativas,
            data_envio
        )
        SELECT
            NEW.id,
            u.email,
            NEW.assunto,
            NEW.mensagem,
            'aguardando',
            0,
            now()
        FROM public.user_expandido u
        WHERE u.id = NEW.id_user_destino
        AND u.email IS NOT NULL;

    -- 2. Scope: 'turma'
    ELSIF NEW.escopo = 'turma' THEN
        INSERT INTO public.email_queue (
            id_thread,
            email_destino,
            assunto,
            mensagem,
            status_fila,
            tentativas,
            data_envio
        )
        SELECT
            NEW.id,
            u.email,
            NEW.assunto,
            NEW.mensagem,
            'aguardando',
            0,
            now()
        FROM public.matriculas m
        JOIN public.user_expandido u ON u.id = m.id_aluno
        WHERE m.id_turma = NEW.id_turma
        AND u.email IS NOT NULL;

    -- 3. Scope: 'area'
    ELSIF NEW.escopo = 'area' THEN
        -- Normaliza o filtro de área recebido
        v_normalized_area := public.normalizar_texto(NEW.filtro_area);

        INSERT INTO public.email_queue (
            id_thread,
            email_destino,
            assunto,
            mensagem,
            status_fila,
            tentativas,
            data_envio
        )
        SELECT DISTINCT
            NEW.id,
            u.email,
            NEW.assunto,
            NEW.mensagem,
            'aguardando',
            0,
            now()
        FROM public.turmas t
        JOIN public.matriculas m ON m.id_turma = t.id
        JOIN public.user_expandido u ON u.id = m.id_aluno
        WHERE 
            -- Compara com a área do curso normalizada
            public.normalizar_texto(t.area_curso) = v_normalized_area
        AND (NEW.ano_semestre IS NULL OR t.ano_semestre = NEW.ano_semestre)
        AND u.email IS NOT NULL;
        
    END IF;

    -- 4. INICIA O CICLO IMEDIATAMENTE
    -- Chama a função de bloqueio para preparar o primeiro lote (10 itens)
    -- Isso já vai setar a thread como 'enviando', disparando o Webhook.
    PERFORM public.fn_email_queue_batch_lock(NEW.id, 10);

    RETURN NEW;
END;
$BODY$;
