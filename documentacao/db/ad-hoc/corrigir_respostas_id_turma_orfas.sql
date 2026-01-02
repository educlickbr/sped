-- 1. Mapeamento Inteligente (Time-Based Match)
-- Para cada resposta órfã, identificamos qual era o processo "Ativo" na época.
-- Regra: Pega o processo mais recente criado ANTES (ou junto) da resposta.
DROP TABLE IF EXISTS tmp_match_temporal;

CREATE TEMP TABLE tmp_match_temporal AS
SELECT DISTINCT ON (r.id)
    r.id AS id_resposta,
    r.user_expandido_id,
    proc.turma_id AS turma_id_destino
FROM public.respostas r
-- Join com Processos do Aluno
JOIN public.processos proc ON proc.user_expandido_id = r.user_expandido_id
JOIN public.turmas t ON proc.turma_id = t.id
WHERE r.id_turma IS NULL
  -- Filtro de escopo da pergunta (Rainha)
  AND EXISTS (SELECT 1 FROM public.processo_documentos_obrigatorios pdo WHERE pdo.id_pergunta = r.id_pergunta AND pdo.escopo = 'turma')
  -- Filtro de Áreas
  AND public.normalizar_texto(t.area_curso) IN ('extensao', 'regulares', 'cursoslivres')
  -- LÓGICA TEMPORAL: O processo deve ter nascido ANTES da resposta
  AND proc.created_at <= r.criado_em
ORDER BY r.id, proc.created_at DESC; 

-- 2. DELETE preventivo (Conflitos)
-- Se já existe resposta na turma "Destino" que descobrimos, a órfã é lixo.
DELETE FROM public.respostas r
USING tmp_match_temporal tmp
WHERE r.id = tmp.id_resposta
  AND EXISTS (
      SELECT 1 
      FROM public.respostas r_existing
      WHERE r_existing.user_expandido_id = tmp.user_expandido_id
        AND r_existing.id_pergunta = r.id_pergunta
        AND r_existing.id_turma = tmp.turma_id_destino
  );

-- 3. UPDATE: Atualiza as que sobraram (seguras)
UPDATE public.respostas r
SET id_turma = tmp.turma_id_destino,
    atualizado_em = NOW()
FROM tmp_match_temporal tmp
WHERE r.id = tmp.id_resposta;

-- 4. Verificação Final (Respostas que continuam órfãs - provavelmente sem processo anterior compatível)
SELECT 
    r.user_expandido_id,
    p.label,
    p.id AS id_pergunta,
    r.criado_em as data_resposta,
    COUNT(DISTINCT r.id) AS qtd_restante,
    ARRAY_AGG(DISTINCT r.id) AS ids_restantes
FROM public.respostas r
JOIN public.perguntas p ON p.id = r.id_pergunta
WHERE r.id_turma IS NULL 
  AND EXISTS (
      SELECT 1 
      FROM public.processo_documentos_obrigatorios pdo 
      WHERE pdo.id_pergunta = r.id_pergunta 
        AND pdo.escopo = 'turma'
  )
GROUP BY r.user_expandido_id, p.label, p.id, r.criado_em
ORDER BY data_resposta DESC;