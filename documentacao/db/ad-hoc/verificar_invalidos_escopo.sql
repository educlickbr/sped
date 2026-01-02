-- Detalhar os 227 casos de "Escopo Inválido"
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
        public.normalizar_texto(t.area_curso) AS area_turma_nova,
        p.label AS pergunta_label
    FROM public.respostas r
    JOIN AlunosMultiProcessos amp ON r.user_expandido_id = amp.user_expandido_id
    JOIN public.processos proc ON proc.user_expandido_id = r.user_expandido_id
    JOIN public.turmas t ON proc.turma_id = t.id
    JOIN public.perguntas p ON r.id_pergunta = p.id
    WHERE 
      EXISTS (SELECT 1 FROM public.processo_documentos_obrigatorios pdo WHERE pdo.id_pergunta = r.id_pergunta AND pdo.escopo = 'turma')
    ORDER BY r.id, ABS(EXTRACT(EPOCH FROM (proc.created_at - r.criado_em))) ASC
)
SELECT 
    ue.nome AS aluno,
    bm.pergunta_label,
    bm.nome_turma_nova AS turma_que_seria_destino,
    bm.area_turma_nova AS area_destino,
    'A pergunta nao esta no PDO dessa turma/area' AS motivo_invalido
FROM BestMatch bm
JOIN public.user_expandido ue ON bm.user_expandido_id = ue.id
WHERE NOT EXISTS (
    -- A condição que define o "Escopo Inválido"
    SELECT 1 FROM public.processo_documentos_obrigatorios pdo
    WHERE pdo.id_pergunta = bm.id_pergunta
      AND pdo.escopo = 'turma'
      AND (
          pdo.id_turma = bm.id_turma_nova
          OR 
          (pdo.id_turma IS NULL AND pdo.id_area::text = bm.area_turma_nova)
      )
)
ORDER BY bm.pergunta_label, ue.nome;
