CREATE TABLE IF NOT EXISTS public.respostas
(
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    id_pergunta uuid,
    id_usuario uuid,
    resposta text COLLATE pg_catalog."default",
    tipo_resposta text COLLATE pg_catalog."default" DEFAULT 'texto'::text,
    criado_em timestamp without time zone DEFAULT now(),
    atualizado_em timestamp without time zone,
    arquivo_original text COLLATE pg_catalog."default",
    user_expandido_id uuid,
    aprovado_doc boolean,
    aprovado_por uuid,
    aprovado_em timestamp with time zone,
    motivo_reprovacao_doc text COLLATE pg_catalog."default",
    id_turma uuid,
    CONSTRAINT respostas_pkey PRIMARY KEY (id),
    CONSTRAINT respostas_aprovado_por_fkey FOREIGN KEY (aprovado_por)
        REFERENCES public.user_expandido (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE SET NULL,
    CONSTRAINT respostas_id_pergunta_fkey FOREIGN KEY (id_pergunta)
        REFERENCES public.perguntas (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT respostas_id_turma_fkey FOREIGN KEY (id_turma)
        REFERENCES public.turmas (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT respostas_id_usuario_fkey FOREIGN KEY (id_usuario)
        REFERENCES auth.users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT respostas_user_expandido_fk FOREIGN KEY (user_expandido_id)
        REFERENCES public.user_expandido (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE public.respostas
    OWNER to postgres;

-- Index: public.idx_respostas_user
CREATE INDEX IF NOT EXISTS idx_respostas_user
    ON public.respostas USING btree
    (id_usuario ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: public.idx_respostas_ux
CREATE INDEX IF NOT EXISTS idx_respostas_ux
    ON public.respostas USING btree
    (user_expandido_id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: public.ix_respostas_aprovacao
CREATE INDEX IF NOT EXISTS ix_respostas_aprovacao
    ON public.respostas USING btree
    (user_expandido_id ASC NULLS LAST, id_pergunta ASC NULLS LAST, aprovado_doc ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: public.ix_respostas_user_pergunta
CREATE INDEX IF NOT EXISTS ix_respostas_user_pergunta
    ON public.respostas USING btree
    (id_usuario ASC NULLS LAST, id_pergunta ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: public.ix_respostas_user_pergunta_global
CREATE UNIQUE INDEX IF NOT EXISTS ix_respostas_user_pergunta_global
    ON public.respostas USING btree
    (user_expandido_id ASC NULLS LAST, id_pergunta ASC NULLS LAST)
    TABLESPACE pg_default
    WHERE id_turma IS NULL;
-- Index: public.ix_respostas_user_pergunta_turma
CREATE UNIQUE INDEX IF NOT EXISTS ix_respostas_user_pergunta_turma
    ON public.respostas USING btree
    (user_expandido_id ASC NULLS LAST, id_pergunta ASC NULLS LAST, id_turma ASC NULLS LAST)
    TABLESPACE pg_default
    WHERE id_turma IS NOT NULL;
-- Trigger: trg_atualiza_imagem_user
CREATE OR REPLACE TRIGGER trg_atualiza_imagem_user
    AFTER INSERT OR UPDATE 
    ON public.respostas
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_atualiza_imagem_user();
-- Trigger: trg_respostas_preencher_usuario_auth
CREATE OR REPLACE TRIGGER trg_respostas_preencher_usuario_auth
    BEFORE INSERT OR UPDATE 
    ON public.respostas
    FOR EACH ROW
    EXECUTE FUNCTION public.dados_preencher_id_usuario();
-- Trigger: trg_respostas_preencher_ux
CREATE OR REPLACE TRIGGER trg_respostas_preencher_ux
    BEFORE INSERT OR UPDATE 
    ON public.respostas
    FOR EACH ROW
    EXECUTE FUNCTION public.perguntas_preencher_id_user_expandido_auth();