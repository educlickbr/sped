-- Select para buscar respostas obrigatórias de um usuário em uma turma
-- Variáveis para substituição:
-- :id_user  -> ID do usuário (auth.users.id)
-- :id_turma -> ID da turma (uuid)
-- :bloco    -> Bloco para filtro (texto) ou NULL para trazer todos

WITH dados_turma AS (
    SELECT 
        id, 
        area_curso 
    FROM public.turmas 
    WHERE id = 'b724b766-6aa3-4489-9237-8ce9c1e7fc3b' -- Substituir pelo ID da turma
),
perguntas_obrigatorias AS (
    SELECT 
        pdo.id_pergunta,
        pdo.bloco,
        pdo.ordem_bloco,
        pdo.ordem,
        pdo.tipo_processo, -- Incluído para diferenciar se houver duplicidade de pergunta em processos diferentes
        p.label AS pergunta_label,
        p.pergunta -- Texto completo da pergunta
    FROM 
        public.processo_documentos_obrigatorios pdo
    JOIN 
        public.perguntas p ON pdo.id_pergunta = p.id
    CROSS JOIN 
        dados_turma dt
    WHERE 
        -- Lógica de Escopo (Area ou Turma)
        -- NÃO FILTRAR por tipo_processo, conforme solicitado ("não filtrar pelo processo da turma")
        (
            (pdo.escopo = 'turma' AND pdo.id_turma = dt.id)
            OR 
            (
                pdo.escopo = 'area' 
                AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(dt.area_curso)
            )
        )
        -- Filtro Opcional de Bloco (comentar ou passar NULL se não usado)
        AND (
            'documentos' IS NULL 
            OR pdo.bloco::text = 'documentos' -- Substituir pelo bloco ou NULL
        )
)
SELECT 
    po.id_pergunta, -- ID da pergunta
    po.pergunta_label,
    po.pergunta, -- Texto da pergunta
    po.bloco,
    po.tipo_processo, -- Útil para saber a origem da obrigatoriedade
    r.resposta,
    CASE 
        WHEN r.id IS NOT NULL THEN TRUE 
        ELSE FALSE 
    END AS respondido
FROM 
    perguntas_obrigatorias po
LEFT JOIN 
    public.respostas r ON r.id_pergunta = po.id_pergunta 
    AND r.id_usuario = 'f161da84-dd88-4f93-839e-6c31963d4391' -- Substituir pelo ID do usuário
ORDER BY 
    po.ordem_bloco, 
    po.ordem;
