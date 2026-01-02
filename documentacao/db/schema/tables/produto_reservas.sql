CREATE TABLE IF NOT EXISTS public.produto_reservas
(
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    id_produto uuid,
    id_produto_estoque uuid,
    id_usuario uuid,
    data_reserva timestamp with time zone DEFAULT now(),
    data_retirada timestamp with time zone,
    data_devolucao timestamp with time zone,
    data_devolvido timestamp with time zone,
    status status_reserva DEFAULT 'reservado'::status_reserva,
    id_avaria uuid,
    usuario_devolveu uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    auth_user_id uuid,
    CONSTRAINT produto_reservas_pkey PRIMARY KEY (id),
    CONSTRAINT produto_reservas_auth_user_id_fkey FOREIGN KEY (auth_user_id)
        REFERENCES auth.users (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE SET NULL,
    CONSTRAINT produto_reservas_id_avaria_fkey FOREIGN KEY (id_avaria)
        REFERENCES public.produto_avarias (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT produto_reservas_id_produto_estoque_fkey FOREIGN KEY (id_produto_estoque)
        REFERENCES public.produto_estoque (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT produto_reservas_id_produto_fkey FOREIGN KEY (id_produto)
        REFERENCES public.produtos (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT produto_reservas_id_usuario_fkey FOREIGN KEY (id_usuario)
        REFERENCES public.user_expandido (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT produto_reservas_usuario_devolveu_fkey FOREIGN KEY (usuario_devolveu)
        REFERENCES public.user_expandido (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE public.produto_reservas
    OWNER to postgres;

-- Index: public.idx_produto_reservas_auth_user_id
CREATE INDEX IF NOT EXISTS idx_produto_reservas_auth_user_id
    ON public.produto_reservas USING btree
    (auth_user_id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: public.idx_reservas_status
CREATE INDEX IF NOT EXISTS idx_reservas_status
    ON public.produto_reservas USING btree
    (status ASC NULLS LAST, id_produto_estoque ASC NULLS LAST)
    TABLESPACE pg_default;
-- Trigger: trg_reservas_aud
CREATE OR REPLACE TRIGGER trg_reservas_aud
    AFTER INSERT OR DELETE OR UPDATE 
    ON public.produto_reservas
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_reservas_status();