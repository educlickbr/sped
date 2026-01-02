-- FIX: Robust Area Matching for Validation Functions
-- 1. Updates _verificar_um_bloco (Helper)
-- 2. Updates verificar_respostas_bloco (Main)

-- ===================================================================
-- 1. HEADER: _verificar_um_bloco
-- ===================================================================
CREATE OR REPLACE FUNCTION public._verificar_um_bloco(
	p_id_user_expandido uuid,
	p_id_turma uuid,
	p_area tipo_area,
	p_bloco text,
	p_idade integer)
    RETURNS jsonb
    LANGUAGE plpgsql
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE 
    v_result jsonb;
BEGIN
    --------------------------------------------------------------------
    -- REGRAS DE IDADE (responsável legal)
    --------------------------------------------------------------------
    IF p_bloco = 'responsavel_legal' 
       AND p_idade IS NOT NULL 
       AND p_idade >= 18 THEN
        RETURN jsonb_build_object('ok', true);
    END IF;

    --------------------------------------------------------------------
    -- O CÉREBRO DA VALIDAÇÃO — CTE obrigatorias
    --------------------------------------------------------------------
    WITH obrigatorias AS (
        SELECT
            p.id AS id_pergunta,
            p.label
        FROM processo_documentos_obrigatorios pdo
        JOIN perguntas p ON p.id = pdo.id_pergunta

        WHERE 
            -- ✔ Bloco deve ser o mesmo na tabela perguntas e na obrigatórios
            p.bloco::text = p_bloco
            AND pdo.bloco::text = p_bloco

            -- ✔ Deve ser obrigatória
            AND pdo.obrigatorio = true

            -- ✔ CONTEXTO REAL DE ÁREA OU TURMA (ROBUST FIX)
            AND (
                   -- Caso 1: Escopo AREA (com normalizacao)
                   (pdo.escopo = 'area' AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(p_area::text))
                   
                   -- Caso 2: Escopo TURMA (especifico OU via Area)
                OR (pdo.escopo = 'turma' AND (
                        pdo.id_turma = p_id_turma
                        OR (
                            pdo.id_turma IS NULL 
                            AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(p_area::text)
                        )
                   ))
            )

            -- ✔ DEPENDÊNCIAS — só entra se a condição for satisfeita
            AND (
                  pdo.depende = false
               OR (
                    pdo.depende = true
                    AND pdo.depende_de IS NOT NULL
                    AND EXISTS (
                        SELECT 1
                        FROM respostas r2
                        WHERE r2.user_expandido_id = p_id_user_expandido
                          AND r2.id_pergunta = pdo.depende_de
                          AND r2.resposta IN (
                              SELECT jsonb_array_elements_text(pdo.valor_depende)
                          )
                    )
               )
            )
    ),

    respostas_user AS (
        SELECT DISTINCT ON (r.id_pergunta)
            r.id_pergunta,
            r.resposta
        FROM respostas r
        WHERE r.user_expandido_id = p_id_user_expandido
          -- FIX Opcional: Garantir que a resposta seja da turma ou global?
          -- O original nao filtrava turma na resposta, assumindo que id_pergunta eh unico por contexto.
          -- Manteremos a logica original de busca.
        ORDER BY r.id_pergunta, r.criado_em DESC
    ),

    faltando AS (
        SELECT 
            o.id_pergunta,
            o.label
        FROM obrigatorias o
        LEFT JOIN respostas_user r ON r.id_pergunta = o.id_pergunta
        WHERE 
            r.resposta IS NULL
            OR trim(r.resposta) = ''
            OR trim(r.resposta) = '[]'
            OR trim(r.resposta) = '{}'
    )

    SELECT 
        CASE 
            WHEN NOT EXISTS (SELECT 1 FROM faltando)
                THEN jsonb_build_object('ok', true)
            ELSE jsonb_build_object(
                'ok', false,
                'bloco', p_bloco,
                'faltando', (
                    SELECT jsonb_agg(
                        jsonb_build_object(
                            'id_pergunta', f.id_pergunta,
                            'label', f.label
                        )
                    )
                    FROM faltando f
                )
            )
        END
    INTO v_result;

    RETURN v_result;
END;
$BODY$;

ALTER FUNCTION public._verificar_um_bloco(uuid, uuid, tipo_area, text, integer) OWNER TO postgres;


-- ===================================================================
-- 2. HEADER: verificar_respostas_bloco
-- ===================================================================
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
    -- 1) Buscar ordem_bloco da PARTIDA (no contexto area/turma ROBUSTO)
    --------------------------------------------------------------------
    SELECT ordem_bloco
    INTO v_op
    FROM processo_documentos_obrigatorios pdo
    WHERE pdo.bloco::text = p_bloco_partida
      AND (
             (pdo.escopo = 'area'  AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(p_area::text))
          OR (pdo.escopo = 'turma' AND (
                 pdo.id_turma = p_id_turma
                 OR (pdo.id_turma IS NULL AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(p_area::text))
             ))
      )
    ORDER BY ordem_bloco
    LIMIT 1;

    --------------------------------------------------------------------
    -- Se tiver DESTINO, buscar ordem_bloco dele tb (mesmo contexto ROBUSTO)
    --------------------------------------------------------------------
    IF p_bloco_destino IS NOT NULL THEN
        SELECT ordem_bloco
        INTO v_od
        FROM processo_documentos_obrigatorios pdo
        WHERE pdo.bloco::text = p_bloco_destino
          AND (
                 (pdo.escopo = 'area'  AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(p_area::text))
              OR (pdo.escopo = 'turma' AND (
                     pdo.id_turma = p_id_turma
                     OR (pdo.id_turma IS NULL AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(p_area::text))
                 ))
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
                     (pdo.escopo = 'area'  AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(p_area::text))
                  OR (pdo.escopo = 'turma' AND (
                         pdo.id_turma = p_id_turma
                         OR (pdo.id_turma IS NULL AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(p_area::text))
                     ))
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
                     (pdo.escopo = 'area'  AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(p_area::text))
                  OR (pdo.escopo = 'turma' AND (
                         pdo.id_turma = p_id_turma
                         OR (pdo.id_turma IS NULL AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(p_area::text))
                     ))
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

ALTER FUNCTION public.verificar_respostas_bloco(uuid, uuid, tipo_area, text, text, integer) OWNER TO postgres;
