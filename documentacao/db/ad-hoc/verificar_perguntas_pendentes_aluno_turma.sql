-- Verificar perguntas obrigatórias não respondidas por um aluno em uma turma
-- 1. Recebe uma turma e um aluno
-- 2. Verifica obrigatoriedade (Prioridade: Turma > Área)
-- 3. Retorna perguntas não respondidas

WITH Params AS (
    SELECT 
        '6c23c7d4-d9b8-4c76-a666-1e4a6e3e0afb'::uuid as entrada_id_turma, -- SUBSTITUIR PELO ID DA TURMA
        '4860edab-09b1-41de-b6ef-3e72a3497924'::uuid as entrada_id_aluno  -- SUBSTITUIR PELO ID DO ALUNO
),
DadosTurma AS (
    SELECT t.id, t.area_curso
    FROM turmas t
    JOIN Params p ON t.id = p.entrada_id_turma
),
-- Verifica se existe ALGUMA configuração para esta turma na tabela de processos
ExisteConfigTurma AS (
    SELECT true as existe
    FROM processo_documentos_obrigatorios pdo
    JOIN Params p ON pdo.id_turma = p.entrada_id_turma
    LIMIT 1
),
PerguntasObrigatorias AS (
    SELECT pdo.id_pergunta
    FROM processo_documentos_obrigatorios pdo, DadosTurma dt
    LEFT JOIN ExisteConfigTurma ect ON true
    WHERE 
        CASE 
            -- Se existe configuração específica para a turma, filtra por ela
            WHEN ect.existe IS TRUE THEN pdo.id_turma = dt.id
            -- Se não existe, procura pelo escopo de área
            ELSE pdo.escopo = 'area' AND pdo.id_area::text = dt.area_curso
        END
        AND pdo.obrigatorio = true 
),
PerguntasPendentes AS (
    SELECT 
        p.id,
        p.pergunta,
        p.label,
        p.tipo
    FROM PerguntasObrigatorias po
    JOIN perguntas p ON p.id = po.id_pergunta
    JOIN Params params ON true
    WHERE NOT EXISTS (
        SELECT 1 
        FROM respostas r 
        WHERE r.id_pergunta = po.id_pergunta 
          AND r.user_expandido_id = params.entrada_id_aluno
    )
)
SELECT * FROM PerguntasPendentes;
