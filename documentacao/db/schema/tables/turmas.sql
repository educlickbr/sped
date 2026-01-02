CREATE TABLE IF NOT EXISTS public.turmas
(
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    nome_curso text COLLATE pg_catalog."default" NOT NULL,
    area_curso text COLLATE pg_catalog."default",
    ano_semestre text COLLATE pg_catalog."default",
    ano text COLLATE pg_catalog."default",
    semestre text COLLATE pg_catalog."default",
    turno text COLLATE pg_catalog."default",
    cod_curso text COLLATE pg_catalog."default",
    cod_turma text COLLATE pg_catalog."default",
    cod_modulo text COLLATE pg_catalog."default",
    qtd_horastotais integer,
    dt_ini_inscri timestamp with time zone,
    dt_fim_inscri timestamp with time zone,
    dt_ini_mat timestamp with time zone,
    dt_fim_mat timestamp with time zone,
    dt_ini_curso timestamp with time zone,
    dt_fim_curso timestamp with time zone,
    dt_ini_inscri_docente timestamp with time zone,
    dt_fim_inscri_docente timestamp with time zone,
    dias_semana text COLLATE pg_catalog."default",
    id_sharepoint integer,
    link_video boolean,
    id_curso uuid,
    hora_ini text COLLATE pg_catalog."default",
    hora_fim text COLLATE pg_catalog."default",
    possui_calendario boolean DEFAULT false,
    log_calendario text COLLATE pg_catalog."default",
    info_calendario jsonb DEFAULT '{}'::jsonb,
    CONSTRAINT turmas_pkey PRIMARY KEY (id),
    CONSTRAINT turmas_id_curso_fkey FOREIGN KEY (id_curso)
        REFERENCES public.curso (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE SET NULL
)

TABLESPACE pg_default;

ALTER TABLE public.turmas
    OWNER to postgres;

-- Index: public.ix_turmas_cod_turma
CREATE INDEX IF NOT EXISTS ix_turmas_cod_turma
    ON public.turmas USING btree
    (cod_turma COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Trigger: trg_sync_link_video_processo
CREATE OR REPLACE TRIGGER trg_sync_link_video_processo
    AFTER INSERT OR UPDATE OF link_video
    ON public.turmas
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_sync_link_video_processo();