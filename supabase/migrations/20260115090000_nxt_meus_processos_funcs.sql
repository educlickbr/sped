-- Function 1: nxt_get_turmas_por_aluno_processos (Strict matching logic from user)
CREATE OR REPLACE FUNCTION public.nxt_get_turmas_por_aluno_processos(p_id_user_expandido uuid)
 RETURNS TABLE(id_processo uuid, id_turma uuid, nome_curso text, area_curso text, area_normalizada text, dt_ini_curso timestamp with time zone, dt_fim_curso timestamp with time zone, status_processo text, nome_aluno text, email_aluno text, id_user_expandido uuid, criado_em timestamp with time zone, documentos_pendentes boolean, dt_ini_inscri timestamp with time zone, dt_fim_inscri timestamp with time zone, dt_ini_mat timestamp with time zone, dt_fim_mat timestamp with time zone, dt_ini_inscri_docente timestamp with time zone, dt_fim_inscri_docente timestamp with time zone, hora_ini text, hora_fim text, lista_pendencias text[])
 LANGUAGE sql
AS $function$

WITH base AS (
    SELECT
        p.id              AS id_processo,
        t.id              AS id_turma,
        c.nome_curso,
        c.area::text      AS area_curso,
        CASE 
          WHEN c.area::text = 'regulares'     THEN 'Regulares'
          WHEN c.area::text = 'cursos_livres' THEN 'Cursos Livres'
          WHEN c.area::text = 'extensao'      THEN 'Extensão'
          ELSE initcap(c.area::text)
        END              AS area_normalizada,

        -- datas principais
        t.dt_ini_curso,
        t.dt_fim_curso,

        -- novas datas da turma
        t.dt_ini_inscri,
        t.dt_fim_inscri,
        t.dt_ini_mat,
        t.dt_fim_mat,
        t.dt_ini_inscri_docente,
        t.dt_fim_inscri_docente,

        -- horários
        t.hora_ini,
        t.hora_fim,

        p.status          AS status_processo,
        concat(ue.nome, ' ', coalesce(ue.sobrenome, '')) AS nome_aluno,
        ue.email          AS email_aluno,
        ue.id             AS id_user_expandido,
        p.created_at      AS criado_em,

        -- usado para filtrar os documentos obrigatórios
        p.tipo_processo,
        p.tipo_candidatura
    FROM processos p
    JOIN turmas t       ON t.id = p.turma_id
    JOIN curso c        ON c.id = t.id_curso
    JOIN user_expandido ue ON ue.id = p.user_expandido_id
    WHERE p.user_expandido_id = p_id_user_expandido
),

-- 🔍 resposta PCD (somente “Sim” conta)
resposta_pcd AS (
    SELECT 
        CASE 
            WHEN trim(r.resposta) = 'Sim'
                THEN 'sim'
            ELSE 'nao'
        END AS pcd_respondeu
    FROM respostas r
    WHERE r.user_expandido_id = p_id_user_expandido
      AND r.id_pergunta = 'eae93308-1e4d-4c67-9c53-c9abf6a31eaf'
    LIMIT 1
),

-- 🔹 Perguntas obrigatórias (arquivo ou link)
obrigatorios_original AS (
    SELECT 
        b.id_turma,
        d.id_pergunta,
        prg.bloco,
        prg.label
    FROM base b
    JOIN processo_documentos_obrigatorios d 
      ON (
           -- escopo por área (NORMALIZADO)
           (d.escopo = 'area'  AND public.normalizar_texto(d.id_area::text) = public.normalizar_texto(b.area_curso))
           -- escopo por turma (específico OU via área)
        OR (d.escopo = 'turma' AND (
                d.id_turma = b.id_turma 
                OR (d.id_turma IS NULL AND public.normalizar_texto(d.id_area::text) = public.normalizar_texto(b.area_curso))
           ))
      )
      -- Filtro de tipo de processo
      AND d.tipo_processo = b.tipo_processo
      -- Filtro de candidatura: EXATA (sem NULL = wildcard)
      AND d.tipo_candidatura = b.tipo_candidatura 
    JOIN perguntas prg ON prg.id = d.id_pergunta
    WHERE d.obrigatorio = TRUE
      -- Apenas ARQUIVO (para pendência)
      AND lower(prg.tipo) = 'arquivo' 
),

-- ❌ Remover documentos do bloco PCD se aluno não respondeu “Sim”
obrigatorios_filtrados AS (
    SELECT *
    FROM obrigatorios_original o
    WHERE NOT (
        o.bloco = 'pcd'
        AND (SELECT pcd_respondeu FROM resposta_pcd) = 'nao'
    )
)

SELECT 
    -- Colunas principais
    b.id_processo,
    b.id_turma,
    b.nome_curso,
    b.area_curso,
    b.area_normalizada,
    b.dt_ini_curso,
    b.dt_fim_curso,
    b.status_processo,
    b.nome_aluno,
    b.email_aluno,
    b.id_user_expandido,
    b.criado_em,

    -- Lógica de pendência
    EXISTS (
        SELECT 1
        FROM obrigatorios_filtrados o
        WHERE o.id_turma = b.id_turma
          AND NOT EXISTS (
              SELECT 1 
              FROM public.respostas r
              WHERE r.user_expandido_id = b.id_user_expandido
                AND r.id_pergunta = o.id_pergunta
                -- Resposta deve ser da turma atual ou global (id_turma IS NULL)
                AND (r.id_turma = b.id_turma OR r.id_turma IS NULL)
          )
    ) AS documentos_pendentes,

    b.dt_ini_inscri,
    b.dt_fim_inscri,
    b.dt_ini_mat,
    b.dt_fim_mat,
    b.dt_ini_inscri_docente,
    b.dt_fim_inscri_docente,
    b.hora_ini,
    b.hora_fim,

    -- Array com labels de pendências (DEBUG)
    ARRAY(
        SELECT o.label
        FROM obrigatorios_filtrados o
        WHERE o.id_turma = b.id_turma
          AND NOT EXISTS (
              SELECT 1 
              FROM public.respostas r
              WHERE r.user_expandido_id = b.id_user_expandido
                AND r.id_pergunta = o.id_pergunta
                AND (r.id_turma = b.id_turma OR r.id_turma IS NULL)
          )
    ) AS lista_pendencias

FROM base b
ORDER BY b.criado_em DESC;
$function$;

-- Function 2: nxt_get_respostas_arquivos_area (Matches logic with above)
CREATE OR REPLACE FUNCTION public.nxt_get_respostas_arquivos_area(
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
  -- 1. Respostas do usuário
  WITH respostas_usuario AS (
      SELECT 
         r.id AS id_resposta,
         r.id_pergunta,
         r.resposta,
         r.arquivo_original,
         r.aprovado_doc,
         r.id_turma,
         r.criado_em
      FROM respostas r
      WHERE r.user_expandido_id = p_id_user_expandido
  ),
  -- Helpers date/age/pcd
  data_nasc AS (
      SELECT resposta::date AS dt_nasc FROM respostas_usuario WHERE id_pergunta = '8925bdc2-538a-408d-bd34-fb64b2638621' AND id_turma IS NULL
  ),
  idade_calc AS (
      SELECT CASE WHEN dt_nasc IS NULL THEN NULL ELSE EXTRACT(YEAR FROM age(current_date, dt_nasc))::int END AS idade FROM data_nasc
  ),
  doc_resp AS ( SELECT resposta FROM respostas_usuario WHERE id_pergunta = '172bf4c5-7609-40d0-a805-d5291fdec84a' AND id_turma IS NULL ),
  pcd AS ( SELECT resposta FROM respostas_usuario WHERE id_pergunta = 'eae93308-1e4d-4c67-9c53-c9abf6a31eaf' AND id_turma IS NULL ),
  laudo_pcd AS ( SELECT resposta FROM respostas_usuario WHERE id_pergunta = 'de76ebe6-38d2-44e1-a112-ee64ad604c4f' AND id_turma IS NULL ),

  -- 2. Seleção de OBRIGATÓRIOS (Strict)
  obrigatorias AS (
      SELECT
        pdo.id_pergunta, p.pergunta, p.label, p.tipo, pdo.bloco, pdo.obrigatorio, pdo.ordem, pdo.leitura, pdo.tipo_candidatura, pdo.largura_coluna, pdo.altura_coluna,
        false::boolean AS artificial, p.tipo AS tipo_resposta, pdo.escopo
      FROM processo_documentos_obrigatorios pdo
      JOIN perguntas p ON p.id = pdo.id_pergunta
      LEFT JOIN idade_calc ic ON TRUE
      LEFT JOIN doc_resp dr ON TRUE
      LEFT JOIN pcd pcdx ON TRUE
      LEFT JOIN laudo_pcd lp ON TRUE
      WHERE 
          pdo.tipo_processo = p_tipo_processo
          -- LOGICA DE ESCOPO COM NORMALIZAÇÃO (Igual a get_turmas)
          AND (
               (pdo.escopo = 'area'  AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(p_area::text))
            OR (
                pdo.escopo = 'turma' 
                AND (
                       pdo.id_turma = p_id_turma 
                    OR (pdo.id_turma IS NULL AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(p_area::text))
                )
            )
          )
          -- APENAS ARQUIVOS e LINKS 
          AND lower(p.tipo) IN ('arquivo', 'link')
          
          -- Filtros Condicionais (Idade, PCD)
          AND (p.id <> '172bf4c5-7609-40d0-a805-d5291fdec84a' OR (COALESCE(ic.idade, 0) < 18 OR dr.resposta IS NOT NULL))
          AND (p.id <> 'de76ebe6-38d2-44e1-a112-ee64ad604c4f' OR (pcdx.resposta ILIKE 'Sim' OR lp.resposta IS NOT NULL))
          
          -- LOGICA DE TIPO_CANDIDATURA ESTRITA (Igual a get_turmas)
          AND (p_tipo_candidatura IS NULL OR pdo.tipo_candidatura IS NULL OR pdo.tipo_candidatura = p_tipo_candidatura)
  ),

  unificado AS (
      SELECT 
        o.*,
        ru.id_pergunta AS resp_pergunta, ru.id_resposta, ru.resposta, ru.arquivo_original, ru.aprovado_doc,
        ru.id_turma AS id_turma_resposta
      FROM obrigatorias o
      LEFT JOIN LATERAL (
        SELECT ru.*
        FROM respostas_usuario ru
        WHERE ru.id_pergunta = o.id_pergunta
        -- Busca de resposta consistente com get_turmas
        AND (ru.id_turma = p_id_turma OR ru.id_turma IS NULL)
        ORDER BY ru.criado_em ASC
        LIMIT 1
      ) ru ON true
      ORDER BY o.id_pergunta
  ),
  
  finalizado AS (
      SELECT jsonb_set(jsonb_set(to_jsonb(u.*), '{uploading}', 'false'::jsonb), '{deleting}', 'false'::jsonb) AS item
      FROM unificado u
  )
  SELECT COALESCE(jsonb_agg(item ORDER BY (item->>'ordem')::int NULLS LAST), '[]'::jsonb) INTO v_result FROM finalizado;

  RETURN v_result;
END;
$function$;
