--corrigido o uso de user_id indevidamente
DROP FUNCTION public.get_respostas_arquivos_area;
CREATE OR REPLACE FUNCTION public.get_respostas_arquivos_area(
    p_tipo_processo tipo_processo,
    p_area tipo_area,
    p_tipo_candidatura tipo_candidatura,
    p_id_user_expandido uuid,
    p_id_turma uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    v_result jsonb;
BEGIN

  ------------------------------------------------------------------
  -- 1. CTE: respostas do usuário
  ------------------------------------------------------------------
  WITH respostas_usuario AS (
      SELECT 
         r.id AS id_resposta,
         r.id_pergunta,
         r.resposta,
         r.arquivo_original,
         r.aprovado_doc
      FROM respostas r
      WHERE r.user_expandido_id = p_id_user_expandido
  ),

  ------------------------------------------------------------------
  -- 2. Dados auxiliares: idade, PCD, doc responsável, laudo
  ------------------------------------------------------------------
  data_nasc AS (
      SELECT resposta::date AS dt_nasc
      FROM respostas_usuario
      WHERE id_pergunta = '8925bdc2-538a-408d-bd34-fb64b2638621'  -- data nascimento
  ),

  idade_calc AS (
      SELECT 
         CASE 
            WHEN dt_nasc IS NULL THEN NULL
            ELSE EXTRACT(YEAR FROM age(current_date, dt_nasc))::int
         END AS idade
      FROM data_nasc
  ),

  doc_resp AS (
      SELECT resposta AS doc_resposta
      FROM respostas_usuario
      WHERE id_pergunta = '172bf4c5-7609-40d0-a805-d5291fdec84a'
  ),

  pcd AS (
      SELECT resposta AS pcd_resposta
      FROM respostas_usuario
      WHERE id_pergunta = 'eae93308-1e4d-4c67-9c53-c9abf6a31eaf'
  ),

  laudo_pcd AS (
      SELECT resposta AS laudo_resposta
      FROM respostas_usuario
      WHERE id_pergunta = 'de76ebe6-38d2-44e1-a112-ee64ad604c4f'
  ),

  ------------------------------------------------------------------
  -- 3. Perguntas obrigatórias aplicáveis (somente arquivo / link)
  --    Regras foram ajustadas para não ocultar quando dados são NULL
  ------------------------------------------------------------------
  obrigatorias AS (
      SELECT
        pdo.id_pergunta,
        p.pergunta,
        p.label,
        p.tipo,
        pdo.bloco,
        pdo.obrigatorio,
        pdo.ordem,
        pdo.leitura,
        pdo.tipo_candidatura,
        pdo.largura_coluna,
        pdo.altura_coluna,
        false::boolean AS artificial,
        p.tipo AS tipo_resposta
      FROM processo_documentos_obrigatorios pdo
      JOIN perguntas p ON p.id = pdo.id_pergunta
      LEFT JOIN idade_calc ic ON TRUE
      LEFT JOIN doc_resp dr ON TRUE
      LEFT JOIN pcd pcdx ON TRUE
      LEFT JOIN laudo_pcd lp ON TRUE
      WHERE 
          pdo.tipo_processo = p_tipo_processo

          -- área ou turma
          AND (
               (pdo.escopo = 'area'  AND pdo.id_area  = p_area)
            OR (pdo.escopo = 'turma' AND pdo.id_turma = p_id_turma)
          )

          -- somente documentos
          AND lower(p.tipo) IN ('arquivo', 'link')

          ----------------------------------------------------------
          -- Regra 1 — Documento do responsável legal
          ----------------------------------------------------------
          AND (
                p.id <> '172bf4c5-7609-40d0-a805-d5291fdec84a'
                OR (
                      -- Menor de idade (idade NULL = assume que precisa)
                      COALESCE(ic.idade, 0) < 18
                      OR dr.doc_resposta IS NOT NULL
                   )
          )

          ----------------------------------------------------------
          -- Regra 2 — Laudo médico PCD
          ----------------------------------------------------------
          AND (
                p.id <> 'de76ebe6-38d2-44e1-a112-ee64ad604c4f'
                OR (
                      -- respondeu "Sim"
                      (pcdx.pcd_resposta ILIKE 'Sim')
                      -- ou já enviou laudo
                      OR (lp.laudo_resposta IS NOT NULL)
                   )
          )

          ----------------------------------------------------------
          -- Regra 3 — Candidatura
          ----------------------------------------------------------
          AND (
                p_tipo_candidatura IS NULL
                OR pdo.tipo_candidatura IS NULL
                OR pdo.tipo_candidatura = p_tipo_candidatura
          )
  ),

  ------------------------------------------------------------------
  -- 4. Respostas do usuário
  ------------------------------------------------------------------
  respostas_user AS (
      SELECT *
      FROM respostas_usuario
  ),

  ------------------------------------------------------------------
  -- 5. Unifica perguntas + respostas
  ------------------------------------------------------------------
  unificado AS (
      SELECT
        o.*,
        ru.id_pergunta AS resp_pergunta,
        ru.id_resposta,
        ru.resposta,
        ru.arquivo_original,
        ru.aprovado_doc
      FROM obrigatorias o
      LEFT JOIN respostas_user ru
        ON ru.id_pergunta = o.id_pergunta
  ),

  ------------------------------------------------------------------
  -- 6. JSON final com flags padrão
  ------------------------------------------------------------------
  finalizado AS (
      SELECT 
        jsonb_set(
          jsonb_set(
            to_jsonb(u.*),
            '{uploading}', 'false'::jsonb
          ),
          '{deleting}', 'false'::jsonb
        ) AS item
      FROM unificado u
  )

  ------------------------------------------------------------------
  -- 7. Agregação final
  ------------------------------------------------------------------
  SELECT COALESCE(
           jsonb_agg(item ORDER BY (item->>'ordem')::int NULLS LAST),
           '[]'::jsonb
         )
  INTO v_result
  FROM finalizado;

  RETURN v_result;

END;
$function$;

ALTER FUNCTION public.get_respostas_arquivos_area(
    tipo_processo,
    tipo_area,
    tipo_candidatura,
    uuid,
    uuid
) OWNER TO postgres;
