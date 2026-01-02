CREATE TABLE IF NOT EXISTS public.diario
(
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    id_aluno uuid NOT NULL,
    id_turma uuid NOT NULL,
    area text COLLATE pg_catalog."default",
    id_item_sharepoint text COLLATE pg_catalog."default",
    justificativa text COLLATE pg_catalog."default",
    data timestamp with time zone NOT NULL,
    p1 status_presenca,
    p2 status_presenca,
    p3 status_presenca,
    p4 status_presenca,
    criado_em timestamp with time zone DEFAULT now(),
    criado_por uuid,
    modificado_em timestamp with time zone DEFAULT now(),
    modificado_por uuid,
    sync_sharepoint boolean NOT NULL DEFAULT false,
    ultima_sync timestamp with time zone,
    atualizado boolean NOT NULL DEFAULT false,
    provisorio_legado boolean NOT NULL DEFAULT false,
    condicao_legado text COLLATE pg_catalog."default",
    log_legado text COLLATE pg_catalog."default",
    area_provisorio text COLLATE pg_catalog."default",
    cod_modulo_provisorio text COLLATE pg_catalog."default",
    id_sharepoint_correto_provisorio text COLLATE pg_catalog."default",
    id_sharepoint_correto_encontrado boolean NOT NULL DEFAULT false,
    data_recebida_texto text COLLATE pg_catalog."default",
    CONSTRAINT diario_pkey PRIMARY KEY (id),
    CONSTRAINT uq_diario_aluno_turma_dia UNIQUE (id_aluno, id_turma, data),
    CONSTRAINT diario_criado_por_fkey FOREIGN KEY (criado_por)
        REFERENCES public.user_expandido (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT diario_id_aluno_fkey FOREIGN KEY (id_aluno)
        REFERENCES public.user_expandido (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT diario_id_turma_fkey FOREIGN KEY (id_turma)
        REFERENCES public.turmas (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT diario_modificado_por_fkey FOREIGN KEY (modificado_por)
        REFERENCES public.user_expandido (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE public.diario
    OWNER to postgres;

-- Index: public.ix_diario_aluno_data
CREATE INDEX IF NOT EXISTS ix_diario_aluno_data
    ON public.diario USING btree
    (id_aluno ASC NULLS LAST, data ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: public.ix_diario_turma_data
CREATE INDEX IF NOT EXISTS ix_diario_turma_data
    ON public.diario USING btree
    (id_turma ASC NULLS LAST, data ASC NULLS LAST)
    TABLESPACE pg_default;
-- Trigger: trg_diario_after_change
CREATE OR REPLACE TRIGGER trg_diario_after_change
    AFTER INSERT OR UPDATE 
    ON public.diario
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_diario_sync();