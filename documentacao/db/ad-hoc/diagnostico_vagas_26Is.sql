-- DIAGNOSTICO DE VAGAS EM 26Is (COM DATAS)
-- Objetivo: Ver quado essas respostas erradas foram criadas e quando os processos onde elas estão foram criados.

WITH RespostasInvalidas26Is AS (
    SELECT 
        r.id AS id_resposta,
        r.user_expandido_id,
        ue.nome as aluno_nome,
        r.id_pergunta,
        p.label as pergunta_label,
        r.id_turma AS id_turma_atual,
        t.nome_curso as nome_turma_atual,
        r.criado_em as resposta_criada_em
    FROM public.respostas r
    JOIN public.turmas t ON r.id_turma = t.id
    JOIN public.user_expandido ue ON r.user_expandido_id = ue.id
    JOIN public.perguntas p ON r.id_pergunta = p.id
    WHERE t.ano_semestre = '26Is'
    -- INVALIDO (Lógica padrão)
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
    AND EXISTS (SELECT 1 FROM public.processo_documentos_obrigatorios pdo WHERE pdo.id_pergunta = r.id_pergunta AND pdo.escopo = 'turma')
)
SELECT 
    ri.user_expandido_id,
    ri.aluno_nome,
    ri.pergunta_label,
    ri.nome_turma_atual AS "ONDE ESTA (ERRADO)",
    to_char(ri.resposta_criada_em, 'DD/MM/YYYY HH24:MI:SS') as data_resposta,
    to_char(proc_errado.created_at, 'DD/MM/YYYY HH24:MI:SS') as data_processo_errado,
    
    -- Busca por VAGAS em 26Is
    COALESCE(
        (
            SELECT jsonb_agg(jsonb_build_object(
                'id_turma_vaga', t_vaga.id,
                'nome_turma_vaga', t_vaga.nome_curso,
                'area_vaga', t_vaga.area_curso
            ))
            FROM public.processos proc
            JOIN public.turmas t_vaga ON proc.turma_id = t_vaga.id
            WHERE proc.user_expandido_id = ri.user_expandido_id
              AND t_vaga.ano_semestre = '26Is'
              -- A turma vaga PRECISA da pergunta
              AND EXISTS (
                  SELECT 1 FROM public.processo_documentos_obrigatorios pdo 
                  WHERE pdo.id_pergunta = ri.id_pergunta 
                  AND pdo.escopo = 'turma'
                  AND (pdo.id_turma = t_vaga.id OR (pdo.id_turma IS NULL AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(t_vaga.area_curso)))
              )
              -- A turma vaga NÃO PODE ter resposta ainda
              AND NOT EXISTS (
                  SELECT 1 FROM public.respostas r_check
                  WHERE r_check.user_expandido_id = ri.user_expandido_id
                    AND r_check.id_pergunta = ri.id_pergunta
                    AND r_check.id_turma = t_vaga.id
              )
        ), 
        '[]'::jsonb
    ) AS "OPCOES_DE_MUDANCA_26Is"

FROM RespostasInvalidas26Is ri
-- Join para pegar a data do processo onde a resposta está (erroneamente)
LEFT JOIN public.processos proc_errado 
    ON proc_errado.user_expandido_id = ri.user_expandido_id 
    AND proc_errado.turma_id = ri.id_turma_atual
ORDER BY ri.resposta_criada_em ASC;
