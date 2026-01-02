-- Investigar DETALHADAMENTE os casos INVALIDO (Escopo Errado)
-- Mostra:
-- 1. Onde tentamos jogar a resposta (Best Match temporal)
-- 2. Por que falhou (Area/Turma nao bate com PDO)
-- 3. Quais OUTROS processos o aluno tem e se algum deles aceitaria essa pergunta

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
        ue.nome as aluno_nome,
        r.id_pergunta,
        p.label as pergunta_label,
        r.id_turma AS id_turma_atual,
        proc.turma_id AS id_turma_nova,
        t.nome_curso as nome_turma_nova,
        public.normalizar_texto(t.area_curso) AS area_turma_nova,
        ABS(EXTRACT(EPOCH FROM (proc.created_at - r.criado_em))) as diff_tempo
    FROM public.respostas r
    JOIN public.user_expandido ue ON r.user_expandido_id = ue.id
    JOIN public.perguntas p ON r.id_pergunta = p.id
    JOIN AlunosMultiProcessos amp ON r.user_expandido_id = amp.user_expandido_id
    JOIN public.processos proc ON proc.user_expandido_id = r.user_expandido_id
    JOIN public.turmas t ON proc.turma_id = t.id
    WHERE 
      EXISTS (SELECT 1 FROM public.processo_documentos_obrigatorios pdo WHERE pdo.id_pergunta = r.id_pergunta AND pdo.escopo = 'turma')
    ORDER BY r.id, ABS(EXTRACT(EPOCH FROM (proc.created_at - r.criado_em))) ASC
),
InvalidMatches AS (
    SELECT * FROM BestMatch bm
    WHERE NOT EXISTS (
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
    im.aluno_nome,
    im.pergunta_label,
    im.nome_turma_nova as "Onde QUERIA ir (Best Match)",
    im.area_turma_nova as "Area Alvo",
    -- Listar todos os processos do aluno e ver se algum servia
    jsonb_agg(
        jsonb_build_object(
            'turma', t_other.nome_curso,
            'area', public.normalizar_texto(t_other.area_curso),
            'ACEITARIA?', CASE WHEN EXISTS (
                SELECT 1 FROM public.processo_documentos_obrigatorios pdo 
                WHERE pdo.id_pergunta = im.id_pergunta 
                AND pdo.escopo = 'turma'
                AND (
                    pdo.id_turma = t_other.id 
                    OR 
                    (pdo.id_turma IS NULL AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(t_other.area_curso))
                )
            ) THEN 'SIM' ELSE 'NAO' END
        )
    ) as "Analise de Outros Processos do Aluno"
FROM InvalidMatches im
JOIN public.processos proc_other ON proc_other.user_expandido_id = im.user_expandido_id
JOIN public.turmas t_other ON proc_other.turma_id = t_other.id
WHERE t_other.ano_semestre = '26Is' -- Ver apenas processos atuais
GROUP BY im.id_resposta, im.aluno_nome, im.pergunta_label, im.nome_turma_nova, im.area_turma_nova
ORDER BY im.pergunta_label, im.aluno_nome;
