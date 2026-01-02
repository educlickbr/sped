CREATE TABLE IF NOT EXISTS public.user_expandido
(
    user_id uuid,
    nome text COLLATE pg_catalog."default",
    sobrenome text COLLATE pg_catalog."default",
    email text COLLATE pg_catalog."default",
    papel_id uuid NOT NULL,
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    imagem_user text COLLATE pg_catalog."default",
    onboarding boolean NOT NULL DEFAULT true,
    papel_modificado boolean DEFAULT false,
    status boolean DEFAULT true,
    CONSTRAINT user_expandido_pkey PRIMARY KEY (id),
    CONSTRAINT user_expandido_email_key UNIQUE (email),
    CONSTRAINT user_expandido_user_id_unique UNIQUE (user_id),
    CONSTRAINT user_expandido_papel_id_fkey FOREIGN KEY (papel_id)
        REFERENCES public.papeis_user (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT user_expandido_user_id_fkey FOREIGN KEY (user_id)
        REFERENCES auth.users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE public.user_expandido
    OWNER to postgres;

-- Trigger: trg_vincular_papel
CREATE OR REPLACE TRIGGER trg_vincular_papel
    AFTER INSERT
    ON public.user_expandido
    FOR EACH ROW
    EXECUTE FUNCTION public.trigger_vincular_papel();