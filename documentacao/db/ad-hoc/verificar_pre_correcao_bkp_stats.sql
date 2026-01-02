-- Estatísticas Pré-Correção (Backup & Escopo)
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
),
Classificacao AS (
    SELECT 
        bm.id_resposta,
        CASE 
            -- 1. Checa Escopo Primeiro
            WHEN NOT EXISTS (
                SELECT 1 FROM public.processo_documentos_obrigatorios pdo
                WHERE pdo.id_pergunta = bm.id_pergunta
                  AND pdo.escopo = 'turma'
                  AND (
                      pdo.id_turma = bm.id_turma_nova
                      OR 
                      (pdo.id_turma IS NULL AND public.normalizar_texto(pdo.id_area::text) = bm.area_turma_nova)
                  )
            ) THEN 'INVALIDO (Escopo Errado)'

            -- 2. Checa se já está no lugar certo
            WHEN bm.id_turma_atual IS NOT DISTINCT FROM bm.id_turma_nova THEN 'OK (Ja estava correto)'

            -- 3. Checa Conflito (Destino Ocupado)
            WHEN EXISTS (
                SELECT 1 FROM public.respostas r_target 
                WHERE r_target.user_expandido_id = bm.user_expandido_id 
                  AND r_target.id_pergunta = bm.id_pergunta
                  AND r_target.id_turma = bm.id_turma_nova
                  AND r_target.id <> bm.id_resposta
            ) THEN 'CONFLITO (Vai pro Backup)'
            
            ELSE 'OK (Sera Atualizado)'
        END AS status_previsao
    FROM BestMatch bm
)
SELECT 
    status_previsao,
    COUNT(*) as quantidade
FROM Classificacao
GROUP BY status_previsao
ORDER BY quantidade DESC;
