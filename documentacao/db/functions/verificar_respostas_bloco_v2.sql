DROP FUNCTION public.verificar_respostas_bloco_v2;  
CREATE OR REPLACE FUNCTION public.verificar_respostas_bloco_v2(
	p_id_user_expandido uuid,
	p_id_turma uuid,
	p_area tipo_area,
	p_bloco_partida text,
	p_bloco_destino text DEFAULT NULL::text,
	p_idade integer DEFAULT NULL::integer,
	p_tipo_processo tipo_processo DEFAULT 'seletivo'::tipo_processo,
	p_tipo_candidatura tipo_candidatura DEFAULT NULL::tipo_candidatura)
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
    -- 1) Buscar ordem_bloco da PARTIDA (no contexto area/turma + processo/candidatura)
    --------------------------------------------------------------------
    SELECT ordem_bloco
    INTO v_op
    FROM processo_documentos_obrigatorios pdo
    WHERE pdo.bloco::text = p_bloco_partida
      AND (
            (pdo.escopo = 'area'  AND pdo.id_area  = p_area)
         OR (pdo.escopo = 'turma' AND pdo.id_turma = p_id_turma)
      )
      -- Filtros V2
      AND pdo.tipo_processo = p_tipo_processo
      AND (pdo.tipo_candidatura IS NULL OR pdo.tipo_candidatura = p_tipo_candidatura)
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
          -- Filtros V2
          AND pdo.tipo_processo = p_tipo_processo
          AND (pdo.tipo_candidatura IS NULL OR pdo.tipo_candidatura = p_tipo_candidatura)
        ORDER BY ordem_bloco
        LIMIT 1;
    END IF;

    --------------------------------------------------------------------
    -- CASO 1 — MODO ANTIGO: só verifica um bloco
    --------------------------------------------------------------------
    IF p_bloco_destino IS NULL THEN
        RETURN (
            SELECT public._verificar_um_bloco_v2(
                p_id_user_expandido,
                p_id_turma,
                p_area,
                p_bloco_partida,
                p_idade,
                p_tipo_processo,
                p_tipo_candidatura
            )
        );
    END IF;

    --------------------------------------------------------------------
    -- CASO 2 — NOVO: validar caminho entre os blocos
    --------------------------------------------------------------------
    IF v_op IS NULL OR v_od IS NULL THEN
        RETURN jsonb_build_object(
            'ok', false,
            'erro', 'Bloco de partida ou destino não encontrado no contexto da área/turma/processo/candidatura.'
        );
    END IF;

    --------------------------------------------------------------------
    -- LÓGICA DE NAVEGAÇÃO
    --------------------------------------------------------------------
    
    -- Se estiver voltando (destino < partida), libera geral.
    IF v_od < v_op THEN
        RETURN jsonb_build_object('ok', true);
    END IF;

    -- Se estiver indo ou ficando, pega intervalo [partida, destino)
    -- Se partida == destino, valida ele mesmo.
    -- Se partida < destino, valida até o anterior ao destino (exclusivo).
    SELECT array_agg(bloco ORDER BY ordem_bloco)
    INTO v_blocos
    FROM (
        SELECT DISTINCT pdo.bloco::text AS bloco, pdo.ordem_bloco
        FROM processo_documentos_obrigatorios pdo
        WHERE 
             -- Filtros de contexto
             (
                (pdo.escopo = 'area'  AND pdo.id_area  = p_area)
             OR (pdo.escopo = 'turma' AND pdo.id_turma = p_id_turma)
             )
             AND pdo.tipo_processo = p_tipo_processo
             AND (pdo.tipo_candidatura IS NULL OR pdo.tipo_candidatura = p_tipo_candidatura)
             
             -- Lógica do intervalo
             AND (
                  (v_op = v_od AND pdo.ordem_bloco = v_op)
                  OR 
                  (v_op < v_od AND pdo.ordem_bloco >= v_op AND pdo.ordem_bloco < v_od)
             )
        ORDER BY pdo.ordem_bloco
    ) sub;

    --------------------------------------------------------------------
    -- valida bloco por bloco
    --------------------------------------------------------------------
    FOREACH v_bloco IN ARRAY v_blocos LOOP
        v_check := public._verificar_um_bloco_v2(
            p_id_user_expandido,
            p_id_turma,
            p_area,
            v_bloco,
            p_idade,
            p_tipo_processo,
            p_tipo_candidatura
        );

        IF (v_check->>'ok')::boolean = false THEN
            RETURN v_check;
        END IF;
    END LOOP;

    RETURN jsonb_build_object('ok', true);
END;
$BODY$;

ALTER FUNCTION public.verificar_respostas_bloco_v2(uuid, uuid, tipo_area, text, text, integer, tipo_processo, tipo_candidatura)
    OWNER TO postgres;
