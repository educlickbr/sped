-- Verificação do STATUS REAL ATUAL (Pós-Correção)
-- Este script ignora o "tempo" e olha apenas para:
-- A turma onde a resposta ESTÁ AGORA é válida?

SELECT 
    CASE 
        WHEN pdo.id IS NOT NULL THEN 'VALIDO (Esta no lugar certo)'
        WHEN r.id_turma IS NULL THEN 'ORFA (Sem turma)'
        ELSE 'INVALIDO (Turma nao aceita essa pergunta)' 
    END AS status_real,
    count(*) as qtd
FROM public.respostas r
JOIN public.turmas t ON r.id_turma = t.id
LEFT JOIN public.processo_documentos_obrigatorios pdo
    ON pdo.id_pergunta = r.id_pergunta
    AND pdo.escopo = 'turma'
    AND (
        pdo.id_turma = r.id_turma
        OR 
        (pdo.id_turma IS NULL AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(t.area_curso))
    )
WHERE 
    -- Focando apenas no contexto do problema (semestre atual)
    t.ano_semestre = '26Is'
    AND EXISTS (SELECT 1 FROM public.processo_documentos_obrigatorios pdo_exists WHERE pdo_exists.id_pergunta = r.id_pergunta AND pdo_exists.escopo = 'turma')
GROUP BY 1
ORDER BY 2 DESC;

-- Detalhar os INVALIDOS SE HOUVER
SELECT 
    ue.nome,
    t.nome_curso as turma_atual,
    public.normalizar_texto(t.area_curso) as area_atual,
    p.label as pergunta
FROM public.respostas r
JOIN public.turmas t ON r.id_turma = t.id
JOIN public.user_expandido ue ON r.user_expandido_id = ue.id
JOIN public.perguntas p ON r.id_pergunta = p.id
LEFT JOIN public.processo_documentos_obrigatorios pdo
    ON pdo.id_pergunta = r.id_pergunta
    AND pdo.escopo = 'turma'
    AND (
        pdo.id_turma = r.id_turma
        OR 
        (pdo.id_turma IS NULL AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(t.area_curso))
    )
WHERE 
    t.ano_semestre = '26Is'
    AND pdo.id IS NULL -- NÃO ACHOU REGRA VACILANDO
    AND EXISTS (SELECT 1 FROM public.processo_documentos_obrigatorios pdo_exists WHERE pdo_exists.id_pergunta = r.id_pergunta AND pdo_exists.escopo = 'turma');
