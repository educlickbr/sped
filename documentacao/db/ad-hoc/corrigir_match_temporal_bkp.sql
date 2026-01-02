-- 1. Calcular o "Best Match" (Mesma lógica)
DROP TABLE IF EXISTS tmp_best_match_bkp;

CREATE TEMP TABLE tmp_best_match_bkp AS
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
          (pdo.id_turma IS NULL AND public.normalizar_texto(pdo.id_area::text) = bm.area_turma_nova)
      )
);

-- 2. CRIAR TABELA DE BACKUP (Permanente)
CREATE TABLE IF NOT EXISTS public.respostas_conflito_bkp AS
SELECT * FROM public.respostas WHERE 1=0;

-- Adiciona colunas extras de metadados
ALTER TABLE public.respostas_conflito_bkp ADD COLUMN IF NOT EXISTS data_arquivamento timestamp DEFAULT NOW();
ALTER TABLE public.respostas_conflito_bkp ADD COLUMN IF NOT EXISTS turma_destino_tentativa uuid; -- Para saber para onde ela ia


-- 3. COPIAR CONFLITOS PARA BACKUP
INSERT INTO public.respostas_conflito_bkp 
(id, id_pergunta, id_usuario, resposta, tipo_resposta, criado_em, atualizado_em, arquivo_original, user_expandido_id, aprovado_doc, aprovado_por, aprovado_em, motivo_reprovacao_doc, id_turma, turma_destino_tentativa)
SELECT 
  r.id, r.id_pergunta, r.id_usuario, r.resposta, r.tipo_resposta, r.criado_em, r.atualizado_em, r.arquivo_original, r.user_expandido_id, r.aprovado_doc, r.aprovado_por, r.aprovado_em, r.motivo_reprovacao_doc, r.id_turma,
  bm.id_turma_nova -- <--- Aqui salvamos o destino que causou o conflito
FROM public.respostas r
JOIN tmp_best_match_bkp bm ON r.id = bm.id_resposta
WHERE
  -- Condição de Conflito: Destino Ocupado
  EXISTS (
      SELECT 1 
      FROM public.respostas r_target
      WHERE r_target.user_expandido_id = bm.user_expandido_id
        AND r_target.id_pergunta = bm.id_pergunta
        AND r_target.id_turma = bm.id_turma_nova
        AND r_target.id <> r.id
  );

-- 4. REMOVER CONFLITOS DA TABELA PRINCIPAL
DELETE FROM public.respostas r
USING tmp_best_match_bkp bm
WHERE r.id = bm.id_resposta
  AND EXISTS (
      SELECT 1 
      FROM public.respostas r_target
      WHERE r_target.user_expandido_id = bm.user_expandido_id
        AND r_target.id_pergunta = bm.id_pergunta
        AND r_target.id_turma = bm.id_turma_nova
        AND r_target.id <> r.id
  );

-- 5. UPDATE NAS RESTANTES
UPDATE public.respostas r
SET id_turma = bm.id_turma_nova,
    atualizado_em = NOW()
FROM tmp_best_match_bkp bm
WHERE r.id = bm.id_resposta
  AND r.id_turma IS DISTINCT FROM bm.id_turma_nova;

-- 6. Verificação
SELECT count(*) as total_movidos FROM public.respostas WHERE atualizado_em > (NOW() - interval '1 minute');
