CREATE OR REPLACE FUNCTION public.verificar_respostas_bloco(
	p_id_user_expandido uuid,
	p_id_turma uuid,
	p_area tipo_area,
	p_bloco_partida text,
	p_bloco_destino text DEFAULT NULL::text,
	p_idade integer DEFAULT NULL::integer)
    RETURNS jsonb
    LANGUAGE plpgsql
    COST 100
    VOLATILE SECURITY DEFINER PARALLEL UNSAFE
AS $BODY$
DECLARE
    v_op int;
    v_od int;
    v_blocos text[];
    v_bloco text;
    v_check jsonb;
BEGIN
    --------------------------------------------------------------------
    -- 1) Buscar ordem_bloco da PARTIDA (no contexto area/turma)
    --------------------------------------------------------------------
    SELECT ordem_bloco
    INTO v_op
    FROM processo_documentos_obrigatorios pdo
    WHERE pdo.bloco::text = p_bloco_partida
      AND (
            (pdo.escopo = 'area'  AND pdo.id_area  = p_area)
         OR (pdo.escopo = 'turma' AND pdo.id_turma = p_id_turma)
      )
    ORDER BY ordem_bloco
    LIMIT 1;

    --------------------------------------------------------------------
    -- Se tiver DESTINO, buscar ordem_bloco dele tb (mesmo contexto)
    --------------------------------------------------------------------
    IF p_bloco_destino IS NOT NULL THEN
        SELECT ordem_bloco
        INTO v_od
        FROM processo_documentos_obrigatorios pdo
        WHERE pdo.bloco::text = p_bloco_destino
          AND (
                (pdo.escopo = 'area'  AND pdo.id_area  = p_area)
             OR (pdo.escopo = 'turma' AND pdo.id_turma = p_id_turma)
          )
        ORDER BY ordem_bloco
        LIMIT 1;
    END IF;

    --------------------------------------------------------------------
    -- CASO 1 — MODO ANTIGO: só verifica um bloco
    --------------------------------------------------------------------
    IF p_bloco_destino IS NULL THEN
        RETURN (
            SELECT public._verificar_um_bloco(
                p_id_user_expandido,
                p_id_turma,
                p_area,
                p_bloco_partida,
                p_idade
            )
        );
    END IF;

    --------------------------------------------------------------------
    -- CASO 2 — NOVO: validar caminho entre os blocos
    --------------------------------------------------------------------
    IF v_op IS NULL OR v_od IS NULL THEN
        RETURN jsonb_build_object(
            'ok', false,
            'erro', 'Bloco de partida ou destino não encontrado no contexto da área/turma.'
        );
    END IF;

    IF v_op <= v_od THEN
        SELECT array_agg(bloco ORDER BY ordem_bloco)
        INTO v_blocos
        FROM (
            SELECT DISTINCT pdo.bloco::text AS bloco, pdo.ordem_bloco
            FROM processo_documentos_obrigatorios pdo
            WHERE pdo.ordem_bloco BETWEEN v_op AND v_od
              AND (
                    (pdo.escopo = 'area'  AND pdo.id_area  = p_area)
                 OR (pdo.escopo = 'turma' AND pdo.id_turma = p_id_turma)
              )
            ORDER BY pdo.ordem_bloco
        ) sub;
    ELSE
        SELECT array_agg(bloco ORDER BY ordem_bloco DESC)
        INTO v_blocos
        FROM (
            SELECT DISTINCT pdo.bloco::text AS bloco, pdo.ordem_bloco
            FROM processo_documentos_obrigatorios pdo
            WHERE pdo.ordem_bloco BETWEEN v_od AND v_op
              AND (
                    (pdo.escopo = 'area'  AND pdo.id_area  = p_area)
                 OR (pdo.escopo = 'turma' AND pdo.id_turma = p_id_turma)
              )
            ORDER BY pdo.ordem_bloco DESC
        ) sub;
    END IF;

    --------------------------------------------------------------------
    -- valida bloco por bloco
    --------------------------------------------------------------------
    FOREACH v_bloco IN ARRAY v_blocos LOOP
        v_check := public._verificar_um_bloco(
            p_id_user_expandido,
            p_id_turma,
            p_area,
            v_bloco,
            p_idade
        );

        IF (v_check->>'ok')::boolean = false THEN
            RETURN v_check;
        END IF;
    END LOOP;

    RETURN jsonb_build_object('ok', true);
END;
$BODY$;

ALTER FUNCTION public.verificar_respostas_bloco(p_id_user_expandido uuid, p_id_turma uuid, p_area tipo_area, p_bloco_partida text, p_bloco_destino text DEFAULT NULL::text, p_idade integer DEFAULT NULL::integer)
    OWNER TO postgres;
