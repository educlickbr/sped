-- Tabela: email_threads
-- Descrição: Tabela principal para agrupar envios de e-mails em threads/assuntos.
-- Autor: Antigravity
-- Data: 2025-12-09

DROP TABLE IF EXISTS public.email_threads CASCADE;

CREATE TABLE IF NOT EXISTS public.email_threads
(
    -- Colunas de Controle
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),

    -- Colunas de Dados
    assunto text NOT NULL,
    mensagem text NOT NULL,
    escopo text NOT NULL, -- 'turma', 'area', 'user'
    ano_semestre text, -- Campo opcional para escopo 'area'
    status_thread text NOT NULL DEFAULT 'pendente'::text, -- 'pendente', 'processando', 'completa', 'erro'
    id_turma uuid,
    id_user_origem uuid,
    id_user_destino uuid, -- Para escopo 'user' (opcional)
    filtro_area text,     -- Para escopo 'area' (opcional, ex: 'Regulares', 'Extensão')

    -- Constraints
    CONSTRAINT email_threads_pkey PRIMARY KEY (id),
    CONSTRAINT email_threads_id_turma_fkey FOREIGN KEY (id_turma)
        REFERENCES public.turmas (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE SET NULL,
    CONSTRAINT email_threads_id_user_origem_fkey FOREIGN KEY (id_user_origem)
        REFERENCES public.user_expandido (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE SET NULL,
    CONSTRAINT email_threads_id_user_destino_fkey FOREIGN KEY (id_user_destino)
        REFERENCES public.user_expandido (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE SET NULL
)
TABLESPACE pg_default;

-- Comentários da Tabela
COMMENT ON TABLE public.email_threads IS 'Tabela que armazena as threads/lotes de envio de e-mails, agrupando mensagens enviadas em massa ou individuais.';

-- Comentários das Colunas
COMMENT ON COLUMN public.email_threads.id IS 'Identificador único da thread (UUID).';
COMMENT ON COLUMN public.email_threads.created_at IS 'Data e hora de criação do registro.';
COMMENT ON COLUMN public.email_threads.updated_at IS 'Data e hora da última atualização do registro.';
COMMENT ON COLUMN public.email_threads.assunto IS 'Assunto principal do e-mail.';
COMMENT ON COLUMN public.email_threads.mensagem IS 'Conteúdo do corpo do e-mail (HTML ou Texto).';
COMMENT ON COLUMN public.email_threads.escopo IS 'Define o escopo do envio: "turma", "area", "user".';
COMMENT ON COLUMN public.email_threads.ano_semestre IS 'Ano/Semestre (Ex: 20251s) utilizado para envios com escopo de área.';
COMMENT ON COLUMN public.email_threads.status_thread IS 'Status atual do processamento da thread: "pendente", "processando", "completa", "erro".';
COMMENT ON COLUMN public.email_threads.id_turma IS 'Referência opcional à turma, caso o escopo seja turma.';
COMMENT ON COLUMN public.email_threads.id_user_origem IS 'Usuário que iniciou o envio/thread (opcional).';
COMMENT ON COLUMN public.email_threads.id_user_destino IS 'Destinatário único quando o escopo é user.';
COMMENT ON COLUMN public.email_threads.filtro_area IS 'Filtro de área (ex: Cursos Livres, Extensão) quando o escopo é area.';
