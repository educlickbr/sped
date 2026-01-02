-- 1. Calcular o "Best Match" com Validação de Escopo
DROP TABLE IF EXISTS tmp_best_match_safe;

CREATE TEMP TABLE tmp_best_match_safe AS
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
        public.normalizar_texto(t.area_curso) AS area_turma_nova
    FROM public.respostas r
    JOIN AlunosMultiProcessos amp ON r.user_expandido_id = amp.user_expandido_id
    JOIN public.processos proc ON proc.user_expandido_id = r.user_expandido_id
    JOIN public.turmas t ON proc.turma_id = t.id
    WHERE 
      EXISTS (SELECT 1 FROM public.processo_documentos_obrigatorios pdo WHERE pdo.id_pergunta = r.id_pergunta AND pdo.escopo = 'turma')
    ORDER BY r.id, ABS(EXTRACT(EPOCH FROM (proc.created_at - r.criado_em))) ASC
)
SELECT * FROM BestMatch bm
WHERE EXISTS (
    SELECT 1 FROM public.processo_documentos_obrigatorios pdo
    WHERE pdo.id_pergunta = bm.id_pergunta
      AND pdo.escopo = 'turma'
      AND (
          pdo.id_turma = bm.id_turma_nova
          OR 
          (pdo.id_turma IS NULL AND pdo.id_area::text = bm.area_turma_nova)
      )
);

-- 2. TRATAMENTO DE CONFLITOS (SEM DELETE)
-- Se a turma de destino JÁ TEM resposta, não podemos mover pra lá (Duplicidade).
-- Mas o usuário não quer deletar.
-- SOLUÇÃO: "Estacionar" a resposta como GLOBAL (NULL) e marcar no texto.
-- Isso só funciona se não houver conflito no Global também (raro em escopo turma).

UPDATE public.respostas r
SET 
  id_turma = NULL,
  resposta = CASE 
      WHEN jsonb_typeof(resposta) = 'string' THEN to_jsonb(r.resposta::text || ' [DUPLICATA_ARCHIVE_' || to_char(NOW(), 'YYYYMMDDHH24MISS') || ']')
      ELSE r.resposta -- Se for objeto/array complexo, mantemos original para não quebrar JSON, ele só vira órfão.
  END,
  atualizado_em = NOW()
FROM tmp_best_match_safe bm
WHERE r.id = bm.id_resposta
  -- Condição de Conflito: Destino Ocupado
  AND EXISTS (
      SELECT 1 
      FROM public.respostas r_target
      WHERE r_target.user_expandido_id = bm.user_expandido_id
        AND r_target.id_pergunta = bm.id_pergunta
        AND r_target.id_turma = bm.id_turma_nova
        AND r_target.id <> r.id
  );

-- 3. UPDATE PADRÃO (Sem Conflitos)
-- Agora que os conflitos foram "removidos" do caminho (viraram NULL), 
-- podemos mover quem sobrou e tem caminho livre.
UPDATE public.respostas r
SET id_turma = bm.id_turma_nova,
    atualizado_em = NOW()
FROM tmp_best_match_safe bm
WHERE r.id = bm.id_resposta
  AND r.id_turma IS DISTINCT FROM bm.id_turma_nova
  -- Garante que não foi arquivado no passo anterior
  AND r.id_turma IS NOT NULL
  -- Garante novamente que o destino está livre (redundancia segurança)
  AND NOT EXISTS (
      SELECT 1 
      FROM public.respostas r_target
      WHERE r_target.user_expandido_id = bm.user_expandido_id
        AND r_target.id_pergunta = bm.id_pergunta
        AND r_target.id_turma = bm.id_turma_nova
        AND r_target.id <> r.id
  );

-- 4. Verificação
SELECT count(*) as total_arquivados FROM public.respostas WHERE resposta::text LIKE '%DUPLICATA_ARCHIVE%' AND atualizado_em > (NOW() - interval '1 minute');
