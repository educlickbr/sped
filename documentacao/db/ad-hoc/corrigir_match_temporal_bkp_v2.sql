START TRANSACTION;

-- 1. Calcular o "Best Match"
DROP TABLE IF EXISTS tmp_best_match_ranked;

CREATE TEMP TABLE tmp_best_match_ranked AS
WITH AlunosMultiProcessos AS (
    SELECT proc.user_expandido_id
    FROM public.processos proc
    JOIN public.turmas t ON proc.turma_id = t.id
    WHERE t.ano_semestre = '26Is'
    GROUP BY proc.user_expandido_id
    HAVING COUNT(*) > 1
),
BestMatch AS (
    SELECT DISTINCT ON (r.id)
        r.id AS id_resposta,
        r.user_expandido_id,
        r.id_pergunta,
        r.id_turma AS id_turma_atual,
        proc.turma_id AS id_turma_nova,
        public.normalizar_texto(t.area_curso) AS area_turma_nova,
        ABS(EXTRACT(EPOCH FROM (proc.created_at - r.criado_em))) as diff_tempo
    FROM public.respostas r
    JOIN AlunosMultiProcessos amp ON r.user_expandido_id = amp.user_expandido_id
    JOIN public.processos proc ON proc.user_expandido_id = r.user_expandido_id
    JOIN public.turmas t ON proc.turma_id = t.id
    WHERE 
      EXISTS (SELECT 1 FROM public.processo_documentos_obrigatorios pdo WHERE pdo.id_pergunta = r.id_pergunta AND pdo.escopo = 'turma')
    ORDER BY r.id, ABS(EXTRACT(EPOCH FROM (proc.created_at - r.criado_em))) ASC
),
FilteredMatch AS (
    SELECT * FROM BestMatch bm
    WHERE EXISTS (
        SELECT 1 FROM public.processo_documentos_obrigatorios pdo
        WHERE pdo.id_pergunta = bm.id_pergunta
          AND pdo.escopo = 'turma'
          AND (
              pdo.id_turma = bm.id_turma_nova
              OR 
              (pdo.id_turma IS NULL AND public.normalizar_texto(pdo.id_area::text) = bm.area_turma_nova)
          )
    )
)
SELECT 
    *,
    ROW_NUMBER() OVER (
        PARTITION BY user_expandido_id, id_pergunta, id_turma_nova 
        ORDER BY diff_tempo ASC
    ) as rn_source
FROM FilteredMatch;

-- 2. CRIAR TABELA DE BACKUP (Permanente)
CREATE TABLE IF NOT EXISTS public.respostas_conflito_bkp_v2 AS
SELECT * FROM public.respostas WHERE 1=0;

ALTER TABLE public.respostas_conflito_bkp_v2 ADD COLUMN IF NOT EXISTS data_arquivamento timestamp DEFAULT NOW();
ALTER TABLE public.respostas_conflito_bkp_v2 ADD COLUMN IF NOT EXISTS turma_destino_tentativa uuid;
ALTER TABLE public.respostas_conflito_bkp_v2 ADD COLUMN IF NOT EXISTS motivo_arquivamento text;

-- 3. COPIAR PARA BACKUP (Source Duplicates + Target Conflicts)
INSERT INTO public.respostas_conflito_bkp_v2
(id, id_pergunta, id_usuario, resposta, tipo_resposta, criado_em, atualizado_em, arquivo_original, user_expandido_id, aprovado_doc, aprovado_por, aprovado_em, motivo_reprovacao_doc, id_turma, turma_destino_tentativa, motivo_arquivamento)
SELECT 
  r.id, r.id_pergunta, r.id_usuario, r.resposta, r.tipo_resposta, r.criado_em, r.atualizado_em, r.arquivo_original, r.user_expandido_id, r.aprovado_doc, r.aprovado_por, r.aprovado_em, r.motivo_reprovacao_doc, r.id_turma,
  bm.id_turma_nova,
  CASE 
    WHEN bm.rn_source > 1 THEN 'DUPLICATA_FONTE'
    ELSE 'CONFLITO_DESTINO'
  END
FROM public.respostas r
JOIN tmp_best_match_ranked bm ON r.id = bm.id_resposta
WHERE
  -- CASO 1: É uma duplicata na origem (perdeu para outra resposta melhor)
  bm.rn_source > 1
  
  OR 
  
  -- CASO 2: É o melhor candidato, mas o destino está ocupado
  (
      bm.rn_source = 1
      AND EXISTS (
          SELECT 1 
          FROM public.respostas r_target
          WHERE r_target.user_expandido_id = bm.user_expandido_id
            AND r_target.id_pergunta = bm.id_pergunta
            AND r_target.id_turma = bm.id_turma_nova
            AND r_target.id <> r.id -- Não é ela mesma
      )
  );

-- 4. REMOVER DO PRINCIPAL (Os mesmos que foram pro backup)
DELETE FROM public.respostas r
USING tmp_best_match_ranked bm
WHERE r.id = bm.id_resposta
AND (
    bm.rn_source > 1
    OR
    (
      bm.rn_source = 1
      AND EXISTS (
          SELECT 1 
          FROM public.respostas r_target
          WHERE r_target.user_expandido_id = bm.user_expandido_id
            AND r_target.id_pergunta = bm.id_pergunta
            AND r_target.id_turma = bm.id_turma_nova
            AND r_target.id <> r.id
      )
    )
);

-- 5. UPDATE NAS RESTANTES (Apenas rank 1 e destino livre)
-- Nota: Como já deletamos os conflitos, o que sobrou na lista de "tmp_best_match_ranked" com rn_source=1
-- PODERIA ser atualizado. PORÉM, se tivermos deletado o registro, ele não existe mais.
-- O UPDATE abaixo só afetará linhas que ainda existem.

UPDATE public.respostas r
SET id_turma = bm.id_turma_nova,
    atualizado_em = NOW()
FROM tmp_best_match_ranked bm
WHERE r.id = bm.id_resposta
  AND bm.rn_source = 1 -- Apenas os vencedores
  AND r.id_turma IS DISTINCT FROM bm.id_turma_nova;

SELECT count(*) as updates_realizados FROM public.respostas WHERE atualizado_em > (NOW() - interval '1 minute');

COMMIT;
