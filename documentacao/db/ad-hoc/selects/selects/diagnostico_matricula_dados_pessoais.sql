-- Query Ad-Hoc para verificar respostas do bloco 'dados_pessoais' no processo 'matricula'
-- Versao 2: Inclui verificacao de tipo da pergunta e status de aprovacao de documentos
-- Parametros:
-- id_user_expandido = 'b1d7ef07-b69c-440c-b2fc-7d7e2b8b9114'
-- user_id = '8025d04a-e023-4b80-a453-523437076278'

WITH target_user AS (
    SELECT id, user_id, nome, email
    FROM public.user_expandido 
    WHERE id = 'b1d7ef07-b69c-440c-b2fc-7d7e2b8b9114' 
       OR user_id = '8025d04a-e023-4b80-a453-523437076278'
    LIMIT 1
),
perguntas_obrigatorias AS (
    SELECT 
        pdo.id_pergunta,
        pdo.obrigatorio,
        pdo.escopo,
        pdo.id_area,
        pdo.id_turma,
        pdo.ordem_bloco,
        pdo.ordem as ordem_pergunta,
        p.pergunta,
        p.tipo,
        p.label
    FROM public.processo_documentos_obrigatorios pdo
    JOIN public.perguntas p ON pdo.id_pergunta = p.id
    WHERE 
        pdo.tipo_processo = 'matricula' 
        AND pdo.bloco::text = 'dados_pessoais'
)
SELECT 
    u.nome as nome_usuario,
    po.ordem_bloco,
    po.ordem_pergunta,
    po.pergunta,
    po.tipo,
    CASE 
        WHEN po.obrigatorio THEN 'SIM' 
        ELSE 'NAO' 
    END as obrigatorio,
    CASE 
        WHEN r.id IS NOT NULL THEN 'RESPONDIDO'
        ELSE 'PENDENTE'
    END as status_resposta,
    r.resposta as valor_resposta,
    r.aprovado_doc,
    r.motivo_reprovacao_doc,
    r.atualizado_em
FROM perguntas_obrigatorias po
CROSS JOIN target_user u
LEFT JOIN public.respostas r 
    ON r.id_pergunta = po.id_pergunta 
    AND r.user_expandido_id = u.id
ORDER BY 
    po.ordem_bloco, 
    po.ordem_pergunta;
