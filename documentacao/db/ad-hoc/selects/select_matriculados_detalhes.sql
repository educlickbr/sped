-- Select para buscar matriculados em um determinado semestre e área com perguntas obrigatórias do PDO
-- Variáveis para substituição:
-- :ano_semestre      -> Ano e Semestre (ex: '26Is')
-- :area_input        -> Área para filtro (ex: 'extensao')
-- :tipo_processo     -> Tipo de processo (default: 'seletivo')
-- :tipo_candidatura  -> Tipo de candidatura (default: 'estudante')

WITH dados_area AS (
    SELECT public.normalizar_texto('extensao'::text) as area_normalizada -- Substituir :area_input
),
perguntas_area AS (
    SELECT 
        pdo.id_pergunta,
        p.pergunta,
        p.label,
        pdo.ordem_bloco,
        pdo.ordem
    FROM 
        public.processo_documentos_obrigatorios pdo
    JOIN 
        public.perguntas p ON pdo.id_pergunta = p.id
    CROSS JOIN 
        dados_area da
    WHERE 
        pdo.escopo = 'area'
        AND public.normalizar_texto(pdo.id_area::text) = da.area_normalizada
        AND pdo.tipo_processo = 'seletivo'::public.tipo_processo -- Substituir :tipo_processo
        AND pdo.tipo_candidatura = 'estudante'::public.tipo_candidatura -- Substituir :tipo_candidatura
)
SELECT 
    ue.nome,
    ue.sobrenome,
    ue.email,
    -- CPF
    (SELECT r.resposta 
     FROM public.respostas r 
     WHERE (r.id_usuario = ue.user_id OR r.user_expandido_id = ue.id) 
       AND r.id_pergunta = '20467206-19d9-4bb9-8a54-e6625f101282' 
     ORDER BY r.criado_em DESC LIMIT 1) as cpf,
    -- RG
    (SELECT r.resposta 
     FROM public.respostas r 
     WHERE (r.id_usuario = ue.user_id OR r.user_expandido_id = ue.id) 
       AND r.id_pergunta = '29a21c21-b102-434e-a05b-08cc5e871de7' 
     ORDER BY r.criado_em DESC LIMIT 1) as rg,
    public.normalizar_texto(t.area_curso) as area_normalizada,
    t.nome_curso as curso,
    jsonb_agg(
        jsonb_build_object(
            'pergunta', pa.pergunta,
            'label', pa.label,
            'resposta', res.resposta,
            'ordem_bloco', pa.ordem_bloco,
            'ordem_pergunta', pa.ordem
        ) ORDER BY pa.ordem_bloco, pa.ordem
    ) as perguntas_respostas_obrigatorias
FROM 
    public.matriculas m
JOIN 
    public.turmas t ON m.id_turma = t.id
JOIN 
    public.user_expandido ue ON m.id_aluno = ue.id
CROSS JOIN 
    dados_area da
-- Join com as perguntas obrigatórias da área
JOIN 
    perguntas_area pa ON true
-- Left join com as respostas para essas perguntas específicas
LEFT JOIN 
    public.respostas res ON (res.user_expandido_id = ue.id OR res.id_usuario = ue.user_id)
    AND res.id_pergunta = pa.id_pergunta
WHERE 
    t.ano_semestre = '26Is' -- Substituir :ano_semestre
    AND public.normalizar_texto(t.area_curso) = da.area_normalizada
    AND m.status::text ILIKE 'Ativ%'
GROUP BY 
    ue.nome, ue.sobrenome, ue.email, ue.user_id, ue.id, t.area_curso, t.nome_curso, da.area_normalizada;
