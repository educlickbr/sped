-- 1. Identificar Alunos com Múltiplos Processos no Semestre '26Is'
DROP TABLE IF EXISTS tmp_best_match_v2;

CREATE TEMP TABLE tmp_best_match_v2 AS
WITH AlunosMultiProcessos AS (
    SELECT proc.user_expandido_id
    FROM public.processos proc
    JOIN public.turmas t ON proc.turma_id = t.id
    WHERE t.ano_semestre = '26Is' -- Semestre confirmado pelo usuário
    GROUP BY proc.user_expandido_id
    HAVING COUNT(*) > 1
)
SELECT DISTINCT ON (r.id)
    r.id AS id_resposta,
    r.user_expandido_id,
    r.id_pergunta, -- Importante para checar colisão
    r.id_turma AS id_turma_atual,
    proc.turma_id AS id_turma_nova,
    ABS(EXTRACT(EPOCH FROM (proc.created_at - r.criado_em))) AS diferenca_segundos
FROM public.respostas r
JOIN AlunosMultiProcessos amp ON r.user_expandido_id = amp.user_expandido_id
JOIN public.processos proc ON proc.user_expandido_id = r.user_expandido_id
WHERE 
  -- Check Rainha (Escopo Turma)
  EXISTS (SELECT 1 FROM public.processo_documentos_obrigatorios pdo WHERE pdo.id_pergunta = r.id_pergunta AND pdo.escopo = 'turma')
ORDER BY r.id, ABS(EXTRACT(EPOCH FROM (proc.created_at - r.criado_em))) ASC;

-- 2. DELETE PREVENTIVO (Conflitos de Unique Key)
-- Se já existe uma resposta na turma de DESTINO, a que estamos tentando mover é redundante.
-- Deletamos ela para limpar a duplicidade e não violar a constraint "ix_respostas_user_pergunta_turma".
DELETE FROM public.respostas r
USING tmp_best_match_v2 bm
WHERE r.id = bm.id_resposta
  -- E existe conflito na turma nova:
  AND EXISTS (
      SELECT 1 
      FROM public.respostas r_target
      WHERE r_target.user_expandido_id = bm.user_expandido_id
        AND r_target.id_pergunta = bm.id_pergunta
        AND r_target.id_turma = bm.id_turma_nova
        AND r_target.id <> r.id -- Garante que não é ela mesma
  );

-- 3. UPDATE (Aplica o match nas restantes)
UPDATE public.respostas r
SET id_turma = bm.id_turma_nova,
    atualizado_em = NOW()
FROM tmp_best_match_v2 bm
WHERE r.id = bm.id_resposta
  -- Só atualiza se o ID de turma for diferente do atual
  AND r.id_turma IS DISTINCT FROM bm.id_turma_nova;

-- 4. Verificação de Progresso
SELECT 
    r.user_expandido_id,
    p.label,
    COUNT(DISTINCT r.id) AS qtd_atualizada
FROM public.respostas r
JOIN public.pergunta p ON p.id = r.id_pergunta
WHERE r.atualizado_em >= (NOW() - interval '1 minute')
GROUP BY r.user_expandido_id, p.label;
