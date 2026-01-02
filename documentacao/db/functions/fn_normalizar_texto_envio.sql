CREATE OR REPLACE FUNCTION public.fn_normalizar_texto_envio(p_texto text)
    RETURNS text
    LANGUAGE 'plpgsql'
    IMMUTABLE
AS $BODY$
DECLARE
    v_texto text;
BEGIN
    IF p_texto IS NULL THEN
        RETURN NULL;
    END IF;

    v_texto := lower(p_texto);
    
    -- Remoção manual de acentos
    v_texto := replace(v_texto, 'á', 'a');
    v_texto := replace(v_texto, 'à', 'a');
    v_texto := replace(v_texto, 'ã', 'a');
    v_texto := replace(v_texto, 'â', 'a');
    v_texto := replace(v_texto, 'ä', 'a');
    
    v_texto := replace(v_texto, 'é', 'e');
    v_texto := replace(v_texto, 'è', 'e');
    v_texto := replace(v_texto, 'ê', 'e');
    v_texto := replace(v_texto, 'ë', 'e');
    
    v_texto := replace(v_texto, 'í', 'i');
    v_texto := replace(v_texto, 'ì', 'i');
    v_texto := replace(v_texto, 'î', 'i');
    v_texto := replace(v_texto, 'ï', 'i');
    
    v_texto := replace(v_texto, 'ó', 'o');
    v_texto := replace(v_texto, 'ò', 'o');
    v_texto := replace(v_texto, 'õ', 'o');
    v_texto := replace(v_texto, 'ô', 'o');
    v_texto := replace(v_texto, 'ö', 'o');
    
    v_texto := replace(v_texto, 'ú', 'u');
    v_texto := replace(v_texto, 'ù', 'u');
    v_texto := replace(v_texto, 'û', 'u');
    v_texto := replace(v_texto, 'ü', 'u');
    
    v_texto := replace(v_texto, 'ç', 'c');
    v_texto := replace(v_texto, 'ñ', 'n');
    
    -- Substituição de separadores
    v_texto := replace(v_texto, ' ', '_');
    v_texto := replace(v_texto, '-', '_');
    
    RETURN v_texto;
END;
$BODY$;



