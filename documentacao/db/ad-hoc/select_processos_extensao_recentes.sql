-- Selecionar processos criados a partir de 03/01/2026 para a área de Extensão
-- Trazendo dados do usuário expandido e nome do curso/turma.

SELECT 
    ue.nome,
    ue.sobrenome,
    ue.email,
    t.nome_curso,
    p.created_at AS data_criacao_processo,
    t.area_curso,
    p.status AS status_processo
FROM 
    processos p
JOIN 
    turmas t ON p.turma_id = t.id
LEFT JOIN 
    user_expandido ue ON p.user_expandido_id = ue.id
WHERE 
    p.created_at >= '2026-01-03 00:00:00-03'
    AND (
           lower(t.area_curso) = 'extensão' 
        OR lower(t.area_curso) = 'extensao'
    )
ORDER BY 
    p.created_at DESC;
