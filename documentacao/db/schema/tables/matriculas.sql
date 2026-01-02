CREATE TABLE IF NOT EXISTS public.matriculas
(
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    id_aluno uuid NOT NULL,
    id_turma uuid NOT NULL,
    status status_matricula NOT NULL DEFAULT 'Ativo'::status_matricula,
    declaracao_matricula boolean NOT NULL DEFAULT false,
    data_envio_declaracao timestamp with time zone,
    arquivo_declaracao text COLLATE pg_catalog."default",
    criado_em timestamp with time zone NOT NULL DEFAULT now(),
    atualizado_em timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT matriculas_pkey PRIMARY KEY (id),
    CONSTRAINT matriculas_id_aluno_id_turma_key UNIQUE (id_aluno, id_turma),
    CONSTRAINT matriculas_id_aluno_fkey FOREIGN KEY (id_aluno)
        REFERENCES public.user_expandido (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT matriculas_id_turma_fkey FOREIGN KEY (id_turma)
        REFERENCES public.turmas (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE public.matriculas
    OWNER to postgres;

-- Index: public.ix_matriculas_aluno
CREATE INDEX IF NOT EXISTS ix_matriculas_aluno
    ON public.matriculas USING btree
    (id_aluno ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: public.ix_matriculas_turma
CREATE INDEX IF NOT EXISTS ix_matriculas_turma
    ON public.matriculas USING btree
    (id_turma ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: public.ix_matriculas_turma_status
CREATE INDEX IF NOT EXISTS ix_matriculas_turma_status
    ON public.matriculas USING btree
    (id_turma ASC NULLS LAST, status ASC NULLS LAST)
    TABLESPACE pg_default;