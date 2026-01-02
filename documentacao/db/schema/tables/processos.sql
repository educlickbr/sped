CREATE TABLE IF NOT EXISTS public.processos
(
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    turma_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    papel_user uuid,
    status text COLLATE pg_catalog."default",
    user_expandido_id uuid,
    tipo_candidatura tipo_candidatura NOT NULL DEFAULT 'estudante'::tipo_candidatura,
    modificado_em timestamp with time zone DEFAULT now(),
    modificado_por uuid,
    documentos_pendentes boolean NOT NULL DEFAULT false,
    envio_email text COLLATE pg_catalog."default" NOT NULL DEFAULT 'Aguardando'::text,
    corrigido boolean NOT NULL DEFAULT false,
    envio_whatsapp text COLLATE pg_catalog."default" NOT NULL DEFAULT 'Aguardando'::text,
    tipo_processo tipo_processo NOT NULL DEFAULT 'seletivo'::tipo_processo,
    CONSTRAINT processos_pkey PRIMARY KEY (id),
    CONSTRAINT fk_turma_id FOREIGN KEY (turma_id)
        REFERENCES public.turmas (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT processos_papel_user_fkey FOREIGN KEY (papel_user)
        REFERENCES public.papeis_user (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT processos_user_expandido_fk FOREIGN KEY (user_expandido_id)
        REFERENCES public.user_expandido (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE public.processos
    OWNER to postgres;

-- Index: public.idx_processos_user
CREATE INDEX IF NOT EXISTS idx_processos_user
    ON public.processos USING btree
    (user_id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: public.idx_processos_ux
CREATE INDEX IF NOT EXISTS idx_processos_ux
    ON public.processos USING btree
    (user_expandido_id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Trigger: trg_processos_modificado
CREATE OR REPLACE TRIGGER trg_processos_modificado
    BEFORE INSERT OR UPDATE 
    ON public.processos
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_processos_set_modificado();
-- Trigger: trg_processos_preencher_ux
CREATE OR REPLACE TRIGGER trg_processos_preencher_ux
    BEFORE INSERT OR UPDATE 
    ON public.processos
    FOR EACH ROW
    EXECUTE FUNCTION public.perguntas_preencher_id_user_expandido_auth();
-- Trigger: trigger_novo_processo
CREATE OR REPLACE TRIGGER trigger_novo_processo
    AFTER INSERT
    ON public.processos
    FOR EACH ROW
    EXECUTE FUNCTION public.notificar_processo_enviado();