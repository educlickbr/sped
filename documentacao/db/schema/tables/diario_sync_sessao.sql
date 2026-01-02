CREATE TABLE IF NOT EXISTS public.diario_sync_sessao
(
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    in_time timestamp with time zone NOT NULL DEFAULT now(),
    status text COLLATE pg_catalog."default" NOT NULL DEFAULT 'aberto'::text,
    CONSTRAINT diario_sync_sessao_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE public.diario_sync_sessao
    OWNER to postgres;

-- Index: public.ix_diario_sync_sessao_in_time
CREATE INDEX IF NOT EXISTS ix_diario_sync_sessao_in_time
    ON public.diario_sync_sessao USING btree
    (in_time ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: public.ix_diario_sync_sessao_status
CREATE INDEX IF NOT EXISTS ix_diario_sync_sessao_status
    ON public.diario_sync_sessao USING btree
    (status COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;