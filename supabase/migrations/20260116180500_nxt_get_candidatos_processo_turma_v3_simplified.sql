DROP FUNCTION IF EXISTS public.nxt_get_candidatos_processo_turma_v3(uuid,integer,integer,tipo_candidatura,text,jsonb,text,boolean,text,text);

CREATE OR REPLACE FUNCTION public.nxt_get_candidatos_processo_turma_v3(
    p_id_turma uuid DEFAULT NULL::uuid, 
    p_pagina integer DEFAULT 1, 
    p_limite integer DEFAULT 20, 
    p_tipo_candidatura tipo_candidatura DEFAULT NULL::tipo_candidatura, 
    p_busca text DEFAULT NULL::text, 
    p_filtros jsonb DEFAULT '[]'::jsonb, 
    p_pcd text DEFAULT NULL::text, 
    p_laudo boolean DEFAULT NULL::boolean, 
    p_ordenar_por text DEFAULT 'nome_completo'::text, 
    p_ordenar_como text DEFAULT 'ASC'::text
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_result  jsonb;
  v_offset  int := (p_pagina - 1) * p_limite;
  v_filtros jsonb := p_filtros;

  -- IDs FIXOS (Respostas do Usuário)
  v_id_genero uuid := '25edf1cb-ed2f-4ae2-a85d-ef5c6f0af8ea';
  v_id_raca   uuid := '9670c817-5db6-4055-8fc9-04cc15d6cd3e';
  v_id_renda  uuid := '98d09feb-ec9a-4a30-882d-7de8099c153f';
  v_id_foto   uuid := 'c95e476a-c4dc-4520-badd-d7392b0aeab7';
  v_id_nome_social uuid := '32b1a387-a2a9-4f79-af30-d32026af64fe';
  v_id_nome_artistico uuid := '5747a06b-2385-4920-af8a-48f8ec870518';
  v_id_data_nascimento uuid := '8925bdc2-538a-408d-bd34-fb64b2638621';
  
  v_id_pcd uuid := 'eae93308-1e4d-4c67-9c53-c9abf6a31eaf';
  v_id_laudo uuid := 'de76ebe6-38d2-44e1-a112-ee64ad604c4f';

  -- IDs DEFERIMENTO
  v_id_deferimento_regulares uuid := '518e1943-1a84-4017-b283-67b3914e46e2';
  v_id_deferimento_livres    uuid := 'cdf7ad73-69bd-4823-978b-ea5367cd1d0b';

BEGIN
  --------------------------------------------------------------------
  -- Normaliza filtros
  --------------------------------------------------------------------
  IF v_filtros IS NULL OR jsonb_typeof(v_filtros) <> 'array' THEN
    v_filtros := '[]'::jsonb;
  END IF;

  WITH

  --------------------------------------------------------------------
  -- BASE: um registro por processo
  --------------------------------------------------------------------
  base AS (
    SELECT
      pr.id         AS id_processo,
      pr.turma_id   AS id_turma,
      pr.created_at AS criado_em,
      pr.status     AS status_processo,
      pr.nota_total_processo,
      t.turno,
      t.nome_curso  AS nome_turma,
      c.nome_curso  AS nome_curso_oficial,
      c.area        AS area_curso,

      ux.id         AS id_user_expandido,
      ux.user_id,
      COALESCE(trim(ux.nome || ' ' || ux.sobrenome), ux.email) AS nome_completo,
      ux.email,
      ux.imagem_user,

      -- PERGUNTAS PADRÃO (Respostas)
      MAX(CASE WHEN r.id_pergunta = v_id_genero         THEN r.resposta        END) AS genero,
      MAX(CASE WHEN r.id_pergunta = v_id_raca           THEN r.resposta        END) AS raca,
      MAX(CASE WHEN r.id_pergunta = v_id_renda          THEN r.resposta        END) AS renda,
      MAX(CASE WHEN r.id_pergunta = v_id_foto           THEN r.arquivo_original END) AS imagem_arquivo,
      MAX(CASE WHEN r.id_pergunta = v_id_nome_social    THEN r.resposta        END) AS nome_social,
      MAX(CASE WHEN r.id_pergunta = v_id_nome_artistico THEN r.resposta        END) AS nome_artistico,
      MAX(CASE WHEN r.id_pergunta = v_id_data_nascimento THEN r.resposta       END) AS data_nascimento,

      -- NOVOS CAMPOS
      MAX(CASE WHEN r.id_pergunta = v_id_pcd   THEN r.resposta        END) AS pcd,
      MAX(CASE WHEN r.id_pergunta = v_id_laudo THEN r.arquivo_original END) AS laudo_arquivo,

      -- Campo Deferimento (da tabela de avaliação, joined via ID do processo)
      -- A lógica é feita no CASE comparando a área e o ID da pergunta correta
      MAX(
        CASE 
          WHEN (c.area = 'regulares' AND rpap.id_pergunta_processo = v_id_deferimento_regulares) THEN rpap.resposta_texto
          WHEN (c.area = 'cursos_livres' AND rpap.id_pergunta_processo = v_id_deferimento_livres) THEN rpap.resposta_texto
          ELSE NULL 
        END
      ) AS deferimento

    FROM public.processos pr
    JOIN public.user_expandido ux ON ux.id = pr.user_expandido_id
    LEFT JOIN public.respostas r   ON r.user_expandido_id = ux.id
    LEFT JOIN public.turmas t      ON t.id = pr.turma_id
    LEFT JOIN public.curso  c      ON c.id = t.id_curso
    
    -- Join com Respostas Avaliação Processo para buscar o Deferimento
    LEFT JOIN public.respostas_perguntas_avaliacao_processos rpap 
      ON rpap.id_processo = pr.id 
      AND (
           (c.area = 'regulares' AND rpap.id_pergunta_processo = v_id_deferimento_regulares)
           OR
           (c.area = 'cursos_livres' AND rpap.id_pergunta_processo = v_id_deferimento_livres)
      )

    WHERE
      (p_id_turma IS NULL OR pr.turma_id = p_id_turma)
      AND (p_tipo_candidatura IS NULL OR pr.tipo_candidatura = p_tipo_candidatura)
      AND (
          p_busca IS NULL
          OR unaccent(ux.nome) ILIKE unaccent('%' || p_busca || '%')
          OR unaccent(ux.sobrenome) ILIKE unaccent('%' || p_busca || '%')
          OR unaccent(ux.nome || ' ' || ux.sobrenome) ILIKE unaccent('%' || p_busca || '%')
      )

    GROUP BY
      pr.id, pr.turma_id, pr.created_at, pr.status, pr.nota_total_processo,
      t.turno, t.nome_curso, c.nome_curso, c.area,
      ux.id, ux.user_id, ux.nome, ux.sobrenome, ux.email, ux.imagem_user

    ORDER BY nome_completo ASC
  ),

  --------------------------------------------------------------------
  -- Filtros DO FRONT
  --------------------------------------------------------------------
  filtros AS (
    SELECT
      (f->>'id_pergunta')::uuid AS id_pergunta,
      f->>'resposta'            AS valor
    FROM jsonb_array_elements(v_filtros) f
  ),

  --------------------------------------------------------------------
  -- Perguntas válidas (Avaliação - Flat)
  --------------------------------------------------------------------
  perguntas_validas AS (
    SELECT
      b.id_user_expandido,
      b.id_processo,
      p.*
    FROM base b
    JOIN perguntas_avaliacao_processos p
      ON p.ativo = TRUE
     AND (
          (p.escopo = 'area'  AND p.area    = b.area_curso)
       OR (p.escopo = 'turma' AND p.id_turma = b.id_turma)
         )
  ),

  avaliacao_flat AS (
    SELECT DISTINCT ON (pv.id_processo, pv.id)
      pv.id_user_expandido,
      pv.id_processo,
      pv.id                  AS id_pergunta,
      pv.pergunta,
      ra.resposta_texto,
      CASE
        WHEN ra.resposta_texto IS NOT NULL THEN ra.resposta_texto
        WHEN pv.tipo = 'opcao'  AND pv.opcao_default IS NOT NULL THEN pv.opcao_default
        WHEN pv.tipo = 'numero' THEN '0'
        ELSE NULL
      END AS resposta_normalizada
    FROM perguntas_validas pv
    LEFT JOIN respostas_perguntas_avaliacao_processos ra
      ON ra.id_pergunta_processo = pv.id
     AND ra.id_user             = pv.id_user_expandido
     AND (
           (pv.escopo = 'area') -- Para area, aceitamos qualquer resposta do user
           OR
           (pv.escopo = 'turma' AND ra.id_processo = pv.id_processo)
           OR ra.id_processo IS NULL
         )
    ORDER BY pv.id_processo, pv.id, CASE WHEN ra.id_processo = pv.id_processo THEN 0 ELSE 1 END, ra.criado_em DESC
  ),

  --------------------------------------------------------------------
  -- FILTROS
  --------------------------------------------------------------------
  filtrado AS (
    SELECT c.*
    FROM base c
    WHERE TRUE

    -- Filtros das perguntas normais (Avaliacao)
    AND NOT EXISTS (
      SELECT 1
      FROM filtros f
      LEFT JOIN avaliacao_flat af
        ON af.id_user_expandido = c.id_user_expandido
       AND af.id_processo       = c.id_processo
       AND af.id_pergunta       = f.id_pergunta
      WHERE af.resposta_normalizada IS DISTINCT FROM f.valor
    )

    -- Filtro PCD
    AND (
      p_pcd IS NULL
      OR (p_pcd = 'sim' AND unaccent(lower(c.pcd)) LIKE '%sim%')
      OR (p_pcd = 'nao' AND (unaccent(lower(c.pcd)) LIKE '%nao%' OR unaccent(lower(c.pcd)) LIKE '%não%' OR unaccent(lower(c.pcd)) LIKE 'n'))
    )

    -- Filtro Laudo
    AND (
      p_laudo IS NULL
      OR (p_laudo = TRUE  AND c.laudo_arquivo IS NOT NULL)
      OR (p_laudo = FALSE AND c.laudo_arquivo IS NULL)
    )
  ),

  --------------------------------------------------------------------
  -- Paginação
  --------------------------------------------------------------------
  final_com_paginacao AS (
    SELECT
      f.*,
      COUNT(*) OVER() AS total_registros
    FROM filtrado f
    ORDER BY
        CASE WHEN p_ordenar_como = 'DESC' AND p_ordenar_por = 'created_at' THEN f.criado_em END DESC,
        CASE WHEN p_ordenar_como = 'DESC' AND p_ordenar_por = 'nome_completo' THEN f.nome_completo END DESC,
        CASE WHEN p_ordenar_como <> 'DESC' AND p_ordenar_por = 'created_at' THEN f.criado_em END ASC,
        CASE WHEN p_ordenar_como <> 'DESC' AND p_ordenar_por = 'nome_completo' THEN f.nome_completo END ASC
    LIMIT p_limite OFFSET v_offset
  )

  --------------------------------------------------------------------
  -- JSON FINAL
  --------------------------------------------------------------------
  SELECT jsonb_build_object(
    'pagina_atual', p_pagina,
    'qtd_paginas',  CEIL(MAX(total_registros) / p_limite::numeric),
    'qtd_total',    COALESCE(MAX(total_registros),0),
    'itens', COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'id_processo',       id_processo,
          'id_turma',          id_turma,
          'criado_em',         criado_em,
          'status_processo',   status_processo,

          'nome_curso',        nome_curso_oficial,
          'nome_turma',        nome_turma,
          'turno',             turno,

          'id_user_expandido', id_user_expandido,
          'nome_completo',     nome_completo,
          'nome_social',       nome_social,
          'nome_artistico',    nome_artistico,
          'email',             email,

          'genero',            genero,
          'raca',              raca,
          'renda',             renda,
          'data_nascimento',   data_nascimento,
          'imagem_user',       COALESCE(imagem_user, imagem_arquivo),
          'nota_total_processo', nota_total_processo,

          'pcd',               pcd,
          'laudo_enviado',     (laudo_arquivo IS NOT NULL),
          'deferimento',       deferimento
        )
      ),
      '[]'::jsonb
    )
  )
  INTO v_result
  FROM final_com_paginacao;

  RETURN v_result;
END
$function$;
