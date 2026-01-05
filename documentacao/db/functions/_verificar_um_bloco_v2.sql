CREATE OR REPLACE FUNCTION public._verificar_um_bloco_v2(
	p_id_user_expandido uuid,
	p_id_turma uuid,
	p_area tipo_area,
	p_bloco text,
	p_idade integer,
	p_tipo_processo tipo_processo DEFAULT 'seletivo'::tipo_processo,
	p_tipo_candidatura tipo_candidatura DEFAULT NULL::tipo_candidatura)
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

            -- ✔ CONTEXTO REAL DE ÁREA OU TURMA
            AND (
                   (pdo.escopo = 'area'  AND pdo.id_area  = p_area)
                OR (pdo.escopo = 'turma' AND pdo.id_turma = p_id_turma)
            )

            -- ✔ FILTRO DE PROCESSO E CANDIDATURA (NOVO V2)
            AND pdo.tipo_processo = p_tipo_processo
             -- Se p_tipo_candidatura for NULL, busca APENAS genéricos (NULL).
             -- Se p_tipo_candidatura tiver valor, busca genéricos OU específicos desse valor.
            AND (
                  (p_tipo_candidatura IS NULL AND pdo.tipo_candidatura IS NULL)
               OR (p_tipo_candidatura IS NOT NULL AND (pdo.tipo_candidatura IS NULL OR pdo.tipo_candidatura = p_tipo_candidatura))
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

ALTER FUNCTION public._verificar_um_bloco_v2(uuid, uuid, tipo_area, text, integer, tipo_processo, tipo_candidatura)
    OWNER TO postgres;
