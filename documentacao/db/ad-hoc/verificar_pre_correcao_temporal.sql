-- 1. Calcular o "Best Match" (Mesma lógica do script de correção)
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
        r.resposta AS resposta_texto,
        r.id_turma AS id_turma_atual,
        proc.turma_id AS id_turma_nova,
        t.nome_curso AS nome_turma_nova,
        public.normalizar_texto(t.area_curso) AS area_turma_nova, -- Importante para check de escopo
        r.criado_em AS data_resposta,
        proc.created_at AS data_processo,
        ABS(EXTRACT(EPOCH FROM (proc.created_at - r.criado_em))) AS diferenca_segundos
    FROM public.respostas r
    JOIN AlunosMultiProcessos amp ON r.user_expandido_id = amp.user_expandido_id
    JOIN public.processos proc ON proc.user_expandido_id = r.user_expandido_id
    JOIN public.turmas t ON proc.turma_id = t.id
    WHERE 
      -- Apenas perguntas que TEM escopo 'turma' definido em algum lugar
      EXISTS (SELECT 1 FROM public.processo_documentos_obrigatorios pdo WHERE pdo.id_pergunta = r.id_pergunta AND pdo.escopo = 'turma')
    ORDER BY r.id, ABS(EXTRACT(EPOCH FROM (proc.created_at - r.criado_em))) ASC
)
-- 2. Exibir o Relatório "Antes vs Depois" Com Validação de Escopo
SELECT 
    ue.nome AS aluno,
    p.label AS pergunta,
    
    -- Situação Atual
    COALESCE(t_atual.nome_curso, 'GLOBAL/NULL') AS turma_atual_nome,
    
    -- Proposta (Pelo Match Temporal)
    bm.nome_turma_nova AS turma_proposta_match,
    bm.diferenca_segundos || ' seg' AS gap_temporal,
    
    -- Status da Mudança
    CASE 
        -- Validação Crucial: A pergunta é válida para a turma proposta?
        WHEN NOT EXISTS (
            SELECT 1 
            FROM public.processo_documentos_obrigatorios pdo
            WHERE pdo.id_pergunta = bm.id_pergunta
              AND pdo.escopo = 'turma'
              AND (
                  -- Configurada especificamente para essa turma
                  pdo.id_turma = bm.id_turma_nova
                  OR 
                  -- OU configurada para a ÁREA dessa turma
                  (pdo.id_turma IS NULL AND pdo.id_area::text = bm.area_turma_nova)
              )
        ) THEN 'INVALIDO (Escopo Incompativel)'

        WHEN bm.id_turma_atual IS NOT DISTINCT FROM bm.id_turma_nova THEN 'MANTER (Ja esta correto)'
        
        -- Verifica conflito de destino ocupado
        WHEN EXISTS (
            SELECT 1 FROM public.respostas r_target 
            WHERE r_target.user_expandido_id = bm.user_expandido_id 
              AND r_target.id_pergunta = bm.id_pergunta
              AND r_target.id_turma = bm.id_turma_nova
              AND r_target.id <> bm.id_resposta
        ) THEN 'CONFLITO (Destino ocupado)'
        
        ELSE 'MOVER (Destino livre)'
    END AS acao_prevista,

    bm.resposta_texto

FROM BestMatch bm
JOIN public.user_expandido ue ON bm.user_expandido_id = ue.id
JOIN public.perguntas p ON bm.id_pergunta = p.id
LEFT JOIN public.turmas t_atual ON bm.id_turma_atual = t_atual.id
ORDER BY acao_prevista DESC, ue.nome;
