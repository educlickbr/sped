CREATE TABLE IF NOT EXISTS public.perguntas
(
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    pergunta text COLLATE pg_catalog."default" NOT NULL,
    label text COLLATE pg_catalog."default",
    tipo text COLLATE pg_catalog."default" NOT NULL,
    bloco bloco_pergunta,
    ordem smallint,
    CONSTRAINT perguntas_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE public.perguntas
    OWNER to postgres;
