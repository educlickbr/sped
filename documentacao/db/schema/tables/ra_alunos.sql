CREATE TABLE IF NOT EXISTS public.ra_alunos
(
    id bigint NOT NULL DEFAULT nextval('ra_alunos_id_seq'::regclass),
    id_aluno uuid NOT NULL,
    ra text COLLATE pg_catalog."default" NOT NULL,
    ra_legado text COLLATE pg_catalog."default",
    ano_ingresso character(4) COLLATE pg_catalog."default" NOT NULL,
    semestre_ingresso smallint NOT NULL,
    ano_semestre_ingresso text COLLATE pg_catalog."default" NOT NULL,
    codigo_lista_ano_semestre smallint NOT NULL,
    milhar integer NOT NULL DEFAULT 1,
    criado_em timestamp with time zone NOT NULL DEFAULT now(),
    atualizado_em timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT ra_alunos_pkey PRIMARY KEY (id),
    CONSTRAINT ra_alunos_ra_key UNIQUE (ra),
    CONSTRAINT ra_alunos_id_aluno_fkey FOREIGN KEY (id_aluno)
        REFERENCES public.user_expandido (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT ra_alunos_codigo_lista_ano_semestre_check CHECK (codigo_lista_ano_semestre >= 1 AND codigo_lista_ano_semestre <= 999),
    CONSTRAINT ra_alunos_milhar_check CHECK (milhar >= 1),
    CONSTRAINT ra_alunos_semestre_ingresso_check CHECK (semestre_ingresso = ANY (ARRAY[1, 2]))
)

TABLESPACE pg_default;

ALTER TABLE public.ra_alunos
    OWNER to postgres;

-- Index: public.ix_ra_lookup
CREATE INDEX IF NOT EXISTS ix_ra_lookup
    ON public.ra_alunos USING btree
    (ano_ingresso COLLATE pg_catalog."default" ASC NULLS LAST, semestre_ingresso ASC NULLS LAST, milhar DESC NULLS FIRST, codigo_lista_ano_semestre DESC NULLS FIRST)
    TABLESPACE pg_default;
-- Index: public.uq_ra_por_aluno
CREATE UNIQUE INDEX IF NOT EXISTS uq_ra_por_aluno
    ON public.ra_alunos USING btree
    (id_aluno ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: public.uq_ra_slot
CREATE UNIQUE INDEX IF NOT EXISTS uq_ra_slot
    ON public.ra_alunos USING btree
    (ano_ingresso COLLATE pg_catalog."default" ASC NULLS LAST, semestre_ingresso ASC NULLS LAST, milhar ASC NULLS LAST, codigo_lista_ano_semestre ASC NULLS LAST)
    TABLESPACE pg_default;
-- Trigger: trg_gerar_ra
CREATE OR REPLACE TRIGGER trg_gerar_ra
    BEFORE INSERT
    ON public.ra_alunos
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_gerar_ra();