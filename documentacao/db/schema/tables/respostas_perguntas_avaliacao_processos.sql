CREATE TABLE IF NOT EXISTS public.respostas_perguntas_avaliacao_processos
(
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    id_user uuid NOT NULL,
    id_pergunta_processo uuid NOT NULL,
    resposta_texto text COLLATE pg_catalog."default",
    criado_por uuid,
    criado_em timestamp with time zone DEFAULT now(),
    id_processo uuid,
    CONSTRAINT respostas_perguntas_avaliacao_processos_pkey PRIMARY KEY (id),
    CONSTRAINT ux_respostas_user_pergunta_processo UNIQUE (id_user, id_pergunta_processo, id_processo),
    CONSTRAINT fk_resposta_processo FOREIGN KEY (id_processo)
        REFERENCES public.processos (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE SET NULL,
    CONSTRAINT respostas_perguntas_avaliacao_process_id_pergunta_processo_fkey FOREIGN KEY (id_pergunta_processo)
        REFERENCES public.perguntas_avaliacao_processos (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT respostas_perguntas_avaliacao_processos_criado_por_fkey FOREIGN KEY (criado_por)
        REFERENCES public.user_expandido (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE SET NULL,
    CONSTRAINT respostas_perguntas_avaliacao_processos_id_user_fkey FOREIGN KEY (id_user)
        REFERENCES public.user_expandido (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE public.respostas_perguntas_avaliacao_processos
    OWNER to postgres;
