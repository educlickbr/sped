-- NEW MIGRATION: Fix nxt_get_turmas_por_aluno_processos return types
-- We need to return tipo_processo and tipo_candidatura so the frontend can pass them to the documents API.

DROP FUNCTION IF EXISTS public.nxt_get_turmas_por_aluno_processos(uuid);

-- Re-create with added columns
CREATE OR REPLACE FUNCTION public.nxt_get_turmas_por_aluno_processos(p_id_user_expandido uuid)
 RETURNS TABLE(
    id_processo uuid, 
    id_turma uuid, 
    nome_curso text, 
    area_curso text, 
    area_normalizada text, 
    dt_ini_curso timestamp with time zone, 
    dt_fim_curso timestamp with time zone, 
    status_processo text, 
    nome_aluno text, 
    email_aluno text, 
    id_user_expandido uuid, 
    criado_em timestamp with time zone, 
    documentos_pendentes boolean, 
    dt_ini_inscri timestamp with time zone, 
    dt_fim_inscri timestamp with time zone, 
    dt_ini_mat timestamp with time zone, 
    dt_fim_mat timestamp with time zone, 
    dt_ini_inscri_docente timestamp with time zone, 
    dt_fim_inscri_docente timestamp with time zone, 
    hora_ini text, 
    hora_fim text, 
    lista_pendencias text[],
    -- New columns
    tipo_processo tipo_processo,
    tipo_candidatura tipo_candidatura
 )
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
    ) AS lista_pendencias,

    -- Retornar os tipos para o frontend
    b.tipo_processo,
    b.tipo_candidatura

FROM base b
ORDER BY b.criado_em DESC;
$function$;
