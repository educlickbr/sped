-- Tabela: email_queue
-- Descrição: Fila de e-mails individuais gerados a partir de uma thread.
-- Autor: Antigravity
-- Data: 2025-12-09

CREATE TABLE IF NOT EXISTS public.email_queue
(
    -- Colunas de Controle
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),

    -- Colunas de Dados
    id_thread uuid NOT NULL,
    email_destino text NOT NULL,
    assunto text NOT NULL, -- Redundância intencional
    mensagem text NOT NULL, -- Redundância intencional
    status_fila text NOT NULL DEFAULT 'aguardando'::text, -- 'aguardando', 'enviando', 'enviado', 'erro'
    tentativas integer NOT NULL DEFAULT 0,
    data_envio timestamp with time zone,

    -- Constraints
    CONSTRAINT email_queue_pkey PRIMARY KEY (id),
    CONSTRAINT email_queue_id_thread_fkey FOREIGN KEY (id_thread)
        REFERENCES public.email_threads (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE -- Se apagar a thread, apaga a fila
)
TABLESPACE pg_default;

-- Comentários da Tabela
COMMENT ON TABLE public.email_queue IS 'Tabela de fila que contém cada e-mail individual a ser enviado, vinculado a uma thread.';

-- Comentários das Colunas
COMMENT ON COLUMN public.email_queue.id IS 'Identificador único do item da fila (UUID).';
COMMENT ON COLUMN public.email_queue.created_at IS 'Data e hora de criação do registro.';
COMMENT ON COLUMN public.email_queue.updated_at IS 'Data e hora da última atualização do registro.';
COMMENT ON COLUMN public.email_queue.id_thread IS 'Referência à thread pai deste e-mail.';
COMMENT ON COLUMN public.email_queue.email_destino IS 'Endereço de e-mail do destinatário.';
COMMENT ON COLUMN public.email_queue.assunto IS 'Assunto do e-mail (copia do da thread para processamento independente).';
COMMENT ON COLUMN public.email_queue.mensagem IS 'Corpo do e-mail (copia do da thread para processamento independente).';
COMMENT ON COLUMN public.email_queue.status_fila IS 'Status do envio individual: "aguardando", "enviando", "enviado", "erro".';
COMMENT ON COLUMN public.email_queue.tentativas IS 'Contador de tentativas de envio falhas.';
COMMENT ON COLUMN public.email_queue.data_envio IS 'Timestamp de quando o e-mail foi efetivamente enviado.';
