-- CORREÇÃO V4: FORÇAR MATCH POR ESCOPO
-- Foco: Pegar respostas que estão em turmas INVALIDAS e move-las para turmas VALIDAS do mesmo aluno, ignorando proximidade temporal inicial.

-- 1. Identificar Respostas Atualmente Invalidas
DROP TABLE IF EXISTS tmp_respostas_invalidas;
CREATE TEMP TABLE tmp_respostas_invalidas AS
SELECT 
    r.id AS id_resposta,
    r.user_expandido_id,
    r.id_pergunta,
    r.criado_em,
    r.id_turma AS id_turma_atual
FROM public.respostas r
JOIN public.turmas t ON r.id_turma = t.id
WHERE t.ano_semestre = '26Is'
  -- INVALIDO: Não existe regra PDO validando esta turma/area
  AND NOT EXISTS (
      SELECT 1 
      FROM public.processo_documentos_obrigatorios pdo
      WHERE pdo.id_pergunta = r.id_pergunta
        AND pdo.escopo = 'turma'
        AND (
            pdo.id_turma = r.id_turma
            OR 
            (pdo.id_turma IS NULL AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(t.area_curso))
        )
  )
  -- Mas a pergunta TEM escopo de turma (não é global pura)
  AND EXISTS (SELECT 1 FROM public.processo_documentos_obrigatorios pdo WHERE pdo.id_pergunta = r.id_pergunta AND pdo.escopo = 'turma');

-- 2. Encontrar Destinos Validos (Alternativas)
DROP TABLE IF EXISTS tmp_match_forcado;
CREATE TEMP TABLE tmp_match_forcado (
    id_resposta uuid,
    user_expandido_id uuid,
    id_pergunta uuid,
    id_turma_atual uuid,
    id_turma_nova uuid,
    diff_tempo double precision,
    rn bigint
);

INSERT INTO tmp_match_forcado
WITH CandidatosValidos AS (
    SELECT 
        ri.id_resposta,
        ri.user_expandido_id,
        ri.id_pergunta,
        ri.id_turma_atual,
        proc.turma_id AS id_turma_nova,
        ABS(EXTRACT(EPOCH FROM (proc.created_at - ri.criado_em))) as diff_tempo
    FROM tmp_respostas_invalidas ri
    JOIN public.processos proc ON proc.user_expandido_id = ri.user_expandido_id
    JOIN public.turmas t ON proc.turma_id = t.id
    -- Removed stricter semester filter to find valid targets in 25Is etc
      -- O Processo candidato TEM que ser valido para a pergunta
      WHERE EXISTS (
        SELECT 1 FROM public.processo_documentos_obrigatorios pdo
        WHERE pdo.id_pergunta = ri.id_pergunta
          AND pdo.escopo = 'turma'
          AND (
              pdo.id_turma = proc.turma_id
              OR 
              (pdo.id_turma IS NULL AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(t.area_curso))
          )
    )
)
SELECT 
    id_resposta,
    user_expandido_id,
    id_pergunta,
    id_turma_atual,
    id_turma_nova,
    diff_tempo,
    ROW_NUMBER() OVER (PARTITION BY id_resposta ORDER BY diff_tempo ASC) as rn
FROM CandidatosValidos;

-- Remove duplicatas de destino ou escolhas ruins
DELETE FROM tmp_match_forcado WHERE rn > 1;


-- 3. TRATAR CONFLITOS NO DESTINO (Se o destino valido ja estiver ocupado)
-- Jogamos a resposta que QUERIA entrar para o backup e deletamos ela, para nao violar Unique Key.
-- (Preferimos deletar a "nova entrante" do que a que ja estava la, pois assumimos que a de lá pode estar certa, ou tratamos na proxima rodada)

INSERT INTO public.respostas_conflito_bkp_v2
(id, id_pergunta, id_usuario, resposta, tipo_resposta, criado_em, atualizado_em, arquivo_original, user_expandido_id, aprovado_doc, aprovado_por, aprovado_em, motivo_reprovacao_doc, id_turma, turma_destino_tentativa, motivo_arquivamento)
SELECT 
  r.id, r.id_pergunta, r.id_usuario, r.resposta, r.tipo_resposta, r.criado_em, r.atualizado_em, r.arquivo_original, r.user_expandido_id, r.aprovado_doc, r.aprovado_por, r.aprovado_em, r.motivo_reprovacao_doc, r.id_turma,
  mf.id_turma_nova,
  'CONFLITO_FORCADO_V4'
FROM public.respostas r
JOIN tmp_match_forcado mf ON r.id = mf.id_resposta
WHERE EXISTS (
    SELECT 1 
    FROM public.respostas r_target
    WHERE r_target.user_expandido_id = mf.user_expandido_id
      AND r_target.id_pergunta = mf.id_pergunta
      AND r_target.id_turma = mf.id_turma_nova
      AND r_target.id <> r.id
);

-- Delete dos conflitos (os que acabamos de fazer backup)
DELETE FROM public.respostas r
USING tmp_match_forcado mf
WHERE r.id = mf.id_resposta
AND EXISTS (
    SELECT 1 
    FROM public.respostas r_target
    WHERE r_target.user_expandido_id = mf.user_expandido_id
      AND r_target.id_pergunta = mf.id_pergunta
      AND r_target.id_turma = mf.id_turma_nova
      AND r_target.id <> r.id
);


-- 4. UPDATE FINAL (Mover quem nao deu conflito)
UPDATE public.respostas r
SET id_turma = mf.id_turma_nova,
    atualizado_em = NOW()
FROM tmp_match_forcado mf
WHERE r.id = mf.id_resposta
  -- Garante que o destino ta livre (ou era ele mesmo, o que nao deve acontecer aqui dada a logica)
  AND NOT EXISTS (
      SELECT 1 
      FROM public.respostas r_target
      WHERE r_target.user_expandido_id = mf.user_expandido_id
        AND r_target.id_pergunta = mf.id_pergunta
        AND r_target.id_turma = mf.id_turma_nova
        AND r_target.id <> r.id
  );

-- Relatorio do que foi feito
SELECT count(*) as itens_movidos_v4 FROM public.respostas WHERE atualizado_em > (NOW() - interval '1 minute');
