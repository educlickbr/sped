CREATE OR REPLACE FUNCTION public.fn_gerar_ra_matricula()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
    v_ano_semestre text;
    v_ano text;
    v_semestre smallint;
BEGIN
    -- Busca ano_semestre da turma
    SELECT ano_semestre INTO v_ano_semestre
    FROM public.turmas
    WHERE id = NEW.id_turma;

    -- Se encontrou a turma e tem ano_semestre preenchido
    IF v_ano_semestre IS NOT NULL THEN
        -- Extrai o ano (assumindo formato YY...) -> 20YY
        -- Ex: 26Is -> 2026
        v_ano := '20' || substring(v_ano_semestre from 1 for 2);
        
        -- Define o semestre baseado no sufixo
        -- Ex: 26Is -> 1, 26IIs -> 2
        IF v_ano_semestre LIKE '%IIs' THEN
            v_semestre := 2;
        ELSIF v_ano_semestre LIKE '%Is' THEN
            v_semestre := 1;
        ELSE 
            -- Se não corresponder ao padrão esperado, não gera RA (ou pode-se logs erro)
            -- Por segurança, retornamos sem fazer nada se o formato for desconhecido
            RETURN NEW; 
        END IF;

        -- Chama a função determinística existente para gerar e inserir o RA
        -- Ora, a função já verifica se o aluno tem RA (idempotência)
        PERFORM public.gerar_ra_aluno_deterministico(
            NEW.id_aluno, 
            v_ano, 
            v_semestre, 
            NULL -- ra_legado
        );
    END IF;

    RETURN NEW;
END;
$BODY$;