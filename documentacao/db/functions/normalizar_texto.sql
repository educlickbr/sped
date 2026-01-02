CREATE OR REPLACE FUNCTION public.normalizar_texto(
	p text)
    RETURNS text
    LANGUAGE plpgsql
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    v text;
BEGIN
    IF p IS NULL THEN
        RETURN NULL;
    END IF;

    -- 1) tira acentos
    v := unaccent(p);

    -- 2) tudo minúsculo
    v := lower(v);

    -- 3) remove tudo que NÃO é letra ou número
    --    MAS com conjunto unicode para garantir consistência visual
    v := regexp_replace(v, '[^a-z0-9]', '', 'g');

    RETURN v;
END;
$BODY$;

ALTER FUNCTION public.normalizar_texto(p text)
    OWNER TO postgres;
