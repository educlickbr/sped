-- 1. Create Trigger Function if not exists
CREATE OR REPLACE FUNCTION public.trg_set_updated_at_curso_ficha()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.modificado_em = now();
  RETURN NEW;
END;
$function$;

-- 2. Create Table
CREATE TABLE IF NOT EXISTS public.curso_ficha_avaliacao (
  id uuid not null default gen_random_uuid (),
  id_curso uuid not null,
  pergunta_1 text not null,
  pergunta_2 text not null,
  pergunta_3 text not null,
  rodape text not null,
  criado_por uuid null,
  modificado_por uuid null,
  criado_em timestamp with time zone not null default now(),
  modificado_em timestamp with time zone not null default now(),
  constraint curso_ficha_avaliacao_pkey primary key (id),
  constraint curso_ficha_avaliacao_id_curso_key unique (id_curso),
  constraint curso_ficha_avaliacao_criado_por_fkey foreign KEY (criado_por) references user_expandido (id) on delete set null,
  constraint curso_ficha_avaliacao_id_curso_fkey foreign KEY (id_curso) references curso (id) on delete CASCADE,
  constraint curso_ficha_avaliacao_modificado_por_fkey foreign KEY (modificado_por) references user_expandido (id) on delete set null
) TABLESPACE pg_default;

-- 3. Create Trigger
DROP TRIGGER IF EXISTS trg_curso_ficha_avaliacao_updated ON public.curso_ficha_avaliacao;
CREATE TRIGGER trg_curso_ficha_avaliacao_updated BEFORE UPDATE ON public.curso_ficha_avaliacao 
FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at_curso_ficha();

-- 4. Create Upsert RPC
CREATE OR REPLACE FUNCTION public.nxt_upsert_ficha_avaliacao(
    p_id_curso uuid,
    p_pergunta_1 text,
    p_pergunta_2 text,
    p_pergunta_3 text,
    p_rodape text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
    INSERT INTO public.curso_ficha_avaliacao (
        id_curso,
        pergunta_1,
        pergunta_2,
        pergunta_3,
        rodape
    )
    VALUES (
        p_id_curso,
        COALESCE(p_pergunta_1, ''),
        COALESCE(p_pergunta_2, ''),
        COALESCE(p_pergunta_3, ''),
        COALESCE(p_rodape, '')
    )
    ON CONFLICT (id_curso) DO UPDATE SET
        pergunta_1 = EXCLUDED.pergunta_1,
        pergunta_2 = EXCLUDED.pergunta_2,
        pergunta_3 = EXCLUDED.pergunta_3,
        rodape = EXCLUDED.rodape,
        modificado_em = now();
END;
$function$;
