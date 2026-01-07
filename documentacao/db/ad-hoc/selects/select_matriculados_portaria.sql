-- Select para buscar matriculados em um determinado semestre com dados expandidos e respostas
-- Variáveis para substituição:
-- :ano_semestre -> Ano e Semestre (ex: '2024-1')

SELECT 
    ue.nome,
    ue.sobrenome,
    ue.email,
    -- CPF (ID: 20467206-19d9-4bb9-8a54-e6625f101282)
    (SELECT r.resposta 
     FROM public.respostas r 
     WHERE (r.id_usuario = ue.user_id OR r.user_expandido_id = ue.id) 
       AND r.id_pergunta = '20467206-19d9-4bb9-8a54-e6625f101282' 
     ORDER BY r.criado_em DESC LIMIT 1) as cpf,
    -- RG (ID: 29a21c21-b102-434e-a05b-08cc5e871de7)
    (SELECT r.resposta 
     FROM public.respostas r 
     WHERE (r.id_usuario = ue.user_id OR r.user_expandido_id = ue.id) 
       AND r.id_pergunta = '29a21c21-b102-434e-a05b-08cc5e871de7' 
     ORDER BY r.criado_em DESC LIMIT 1) as rg,
    public.normalizar_texto(t.area_curso) as area,
    t.nome_curso as curso,
    jsonb_agg(
        jsonb_build_object(
            'pergunta', p.pergunta,
            'label', p.label,
            'resposta', res.resposta
        )
    ) as perguntas_respostas
FROM 
    public.matriculas m
JOIN 
    public.turmas t ON m.id_turma = t.id
JOIN 
    public.user_expandido ue ON m.id_aluno = ue.id
-- Trazer todas as respostas do usuário que pertencem a alguma pergunta cadastrada
LEFT JOIN 
    public.respostas res ON (res.user_expandido_id = ue.id OR res.id_usuario = ue.user_id)
LEFT JOIN 
    public.perguntas p ON res.id_pergunta = p.id
WHERE 
    t.ano_semestre = '26Is' -- Substituir pelo :ano_semestre desejado
    AND m.status::text ILIKE 'Ativ%'
GROUP BY 
    ue.nome, ue.sobrenome, ue.email, ue.user_id, ue.id, t.area_curso, t.nome_curso;
