-- 1. Calcular o "Best Match" com Validação de Escopo
DROP TABLE IF EXISTS tmp_best_match_final;

CREATE TEMP TABLE tmp_best_match_final AS
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
      -- Apenas perguntas que TEM escopo 'turma' definido
      EXISTS (SELECT 1 FROM public.processo_documentos_obrigatorios pdo WHERE pdo.id_pergunta = r.id_pergunta AND pdo.escopo = 'turma')
    ORDER BY r.id, ABS(EXTRACT(EPOCH FROM (proc.created_at - r.criado_em))) ASC
)
SELECT * FROM BestMatch bm
WHERE EXISTS (
    -- VALIDAÇÃO DE ESCOPO: Só mantemos o match se a pergunta for válida para a turma/área nova
    SELECT 1 
    FROM public.processo_documentos_obrigatorios pdo
    WHERE pdo.id_pergunta = bm.id_pergunta
      AND pdo.escopo = 'turma'
      AND (
          pdo.id_turma = bm.id_turma_nova
          OR 
          (pdo.id_turma IS NULL AND pdo.id_area::text = bm.area_turma_nova)
      )
);

-- 2. DELETE PREVENTIVO (Resolver Conflitos)
-- Se a turma de destino JÁ TEM resposta, apagamos a que estamos tentando mover (redundante).
DELETE FROM public.respostas r
USING tmp_best_match_final bm
WHERE r.id = bm.id_resposta
  AND EXISTS (
      SELECT 1 
      FROM public.respostas r_target
      WHERE r_target.user_expandido_id = bm.user_expandido_id
        AND r_target.id_pergunta = bm.id_pergunta
        AND r_target.id_turma = bm.id_turma_nova
        AND r_target.id <> r.id
  );

-- 3. UPDATE (Mover as respostas seguras)
UPDATE public.respostas r
SET id_turma = bm.id_turma_nova,
    atualizado_em = NOW()
FROM tmp_best_match_final bm
WHERE r.id = bm.id_resposta
  AND r.id_turma IS DISTINCT FROM bm.id_turma_nova;

-- 4. Verificação Final e Limpeza de Lixo (Opcional)
-- Conta quantos foram atualizados
SELECT count(*) as total_atualizados FROM public.respostas WHERE atualizado_em > (NOW() - interval '1 minute');
