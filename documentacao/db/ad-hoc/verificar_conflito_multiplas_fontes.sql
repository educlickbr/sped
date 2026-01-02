-- Identificar se existem multiplas respostas do mesmo usuario/pergunta querendo ir para a MESMA turma nova
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
        public.normalizar_texto(t.area_curso) AS area_turma_nova,
        ABS(EXTRACT(EPOCH FROM (proc.created_at - r.criado_em))) as diff_tempo
    FROM public.respostas r
    JOIN AlunosMultiProcessos amp ON r.user_expandido_id = amp.user_expandido_id
    JOIN public.processos proc ON proc.user_expandido_id = r.user_expandido_id
    JOIN public.turmas t ON proc.turma_id = t.id
    WHERE 
      EXISTS (SELECT 1 FROM public.processo_documentos_obrigatorios pdo WHERE pdo.id_pergunta = r.id_pergunta AND pdo.escopo = 'turma')
    ORDER BY r.id, ABS(EXTRACT(EPOCH FROM (proc.created_at - r.criado_em))) ASC
),
ValidMatches AS (
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
    )
    AND bm.id_turma_atual IS DISTINCT FROM bm.id_turma_nova -- Só as que vão mover
),
DuplicatasDestino AS (
    SELECT 
        user_expandido_id, 
        id_pergunta, 
        id_turma_nova, 
        COUNT(*) as qtd_fontes,
        array_agg(id_resposta) as ids_respostas
    FROM ValidMatches
    GROUP BY user_expandido_id, id_pergunta, id_turma_nova
    HAVING COUNT(*) > 1
)
SELECT * FROM DuplicatasDestino;
