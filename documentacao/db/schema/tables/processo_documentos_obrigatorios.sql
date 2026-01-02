CREATE TABLE IF NOT EXISTS public.processo_documentos_obrigatorios
(
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    escopo escopo_processo NOT NULL,
    id_area tipo_area,
    id_curso uuid,
    id_turma uuid,
    id_pergunta uuid NOT NULL,
    obrigatorio boolean NOT NULL DEFAULT true,
    observacoes text COLLATE pg_catalog."default",
    tipo_processo tipo_processo NOT NULL DEFAULT 'seletivo'::tipo_processo,
    bloco bloco_pergunta,
    ordem smallint,
    leitura boolean NOT NULL DEFAULT false,
    tipo_candidatura tipo_candidatura,
    largura_coluna largura_coluna_tipo,
    altura_coluna altura_coluna_tipo,
    largura integer,
    altura integer,
    depende boolean NOT NULL DEFAULT false,
    depende_de uuid,
    valor_depende jsonb,
    pergunta_gatilho boolean NOT NULL DEFAULT false,
    valor_gatilho text COLLATE pg_catalog."default",
    ordem_bloco integer,
    CONSTRAINT processo_documentos_obrigatorios_pkey PRIMARY KEY (id),
    CONSTRAINT processo_documentos_obrigatorios_id_curso_fkey FOREIGN KEY (id_curso)
        REFERENCES public.curso (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT processo_documentos_obrigatorios_id_pergunta_fkey FOREIGN KEY (id_pergunta)
        REFERENCES public.perguntas (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT processo_documentos_obrigatorios_id_turma_fkey FOREIGN KEY (id_turma)
        REFERENCES public.turmas (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT chk_escopo_area CHECK (escopo <> 'area'::escopo_processo OR id_area IS NOT NULL),
    CONSTRAINT chk_escopo_curso CHECK (escopo <> 'curso'::escopo_processo OR id_curso IS NOT NULL),
    CONSTRAINT chk_escopo_turma CHECK (escopo <> 'turma'::escopo_processo OR id_turma IS NOT NULL OR id_area IS NOT NULL)
)

TABLESPACE pg_default;

ALTER TABLE public.processo_documentos_obrigatorios
    OWNER to postgres;
