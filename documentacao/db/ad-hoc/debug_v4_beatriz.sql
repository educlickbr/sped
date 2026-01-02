-- DEBUG V4 LOGIC PARA BEATRIZ (30be632a-2741-4ddf-89dc-226dfb73a633)

-- 1. Verificar se ela é detectada como INVALIDA
WITH RespostaBeatriz AS (
    SELECT 
        r.id AS id_resposta,
        r.user_expandido_id,
        r.id_pergunta,
        r.id_turma AS id_turma_atual,
        t.nome_curso,
        t.area_curso,
        t.ano_semestre
    FROM public.respostas r
    JOIN public.turmas t ON r.id_turma = t.id
    WHERE r.user_expandido_id = '30be632a-2741-4ddf-89dc-226dfb73a633'
    -- Filtra pela pergunta da Carta de Intenção (ou pega todas para garantir)
    -- AND r.id_pergunta = ... 
),
CheckInvalidez AS (
    SELECT *,
        -- Check se existe regra PDO validando o local atual
        EXISTS (
            SELECT 1 
            FROM public.processo_documentos_obrigatorios pdo
            WHERE pdo.id_pergunta = rb.id_pergunta
              AND pdo.escopo = 'turma'
              AND (
                  pdo.id_turma = rb.id_turma_atual
                  OR 
                  (pdo.id_turma IS NULL AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(rb.area_curso))
              )
        ) as is_valid_pdo
    FROM RespostaBeatriz rb
),
-- 2. Verificar se encontramos um DESTINO VALIDO
Candidatos AS (
    SELECT 
        rb.id_resposta,
        proc.turma_id AS id_turma_candidata,
        t.nome_curso as nome_turma_candidata,
        t.area_curso as area_candidata,
        -- Check se esse candidato é valido
        EXISTS (
            SELECT 1 FROM public.processo_documentos_obrigatorios pdo
            WHERE pdo.id_pergunta = rb.id_pergunta
              AND pdo.escopo = 'turma'
              AND (
                  pdo.id_turma = proc.turma_id
                  OR 
                  (pdo.id_turma IS NULL AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(t.area_curso))
              )
        ) as is_candidate_valid
    FROM RespostaBeatriz rb
    JOIN public.processos proc ON proc.user_expandido_id = rb.user_expandido_id
    JOIN public.turmas t ON proc.turma_id = t.id
    WHERE t.ano_semestre = '26Is'
)
SELECT 
    '1. ANALISE ATUAL' as step,
    id_resposta, id_turma_atual, nome_curso, area_curso, is_valid_pdo, NULL as target_name, NULL as target_valid
FROM CheckInvalidez

UNION ALL

SELECT 
    '2. CANDIDATO ENCONTRADO' as step,
    id_resposta, NULL, NULL, NULL, NULL, nome_turma_candidata, is_candidate_valid
FROM Candidatos;
