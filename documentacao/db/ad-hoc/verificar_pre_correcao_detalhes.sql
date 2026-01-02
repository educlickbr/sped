SELECT 
    p.label AS "Pergunta",
    
    -- Resposta que vai ficar (Global/Original)
    r_keep.resposta AS "Resposta [MANTER]",
    r_keep.criado_em AS "Data [MANTER]",
    
    -- Resposta que vai ser apagada (Duplicata com Turma)
    r_delete.resposta AS "Resposta [APAGAR]",
    r_delete.criado_em AS "Data [APAGAR]",

    -- Metadados
    r_delete.user_expandido_id,
    CASE WHEN r_keep.resposta = r_delete.resposta THEN 'IGUAIS' ELSE 'DIFERENTES' END AS "Comparacao"

FROM public.respostas r_delete
JOIN public.perguntas p ON p.id = r_delete.id_pergunta
-- Join com a versão GLOBAL (que vai ser mantida)
JOIN public.respostas r_keep 
    ON r_keep.user_expandido_id = r_delete.user_expandido_id
    AND r_keep.id_pergunta = r_delete.id_pergunta
    AND r_keep.id_turma IS NULL

WHERE r_delete.id_turma IS NOT NULL
  -- Filtra apenas as que não deveriam ser turma (segundo a Rainha)
  AND NOT EXISTS (
      SELECT 1 
      FROM public.processo_documentos_obrigatorios pdo
      WHERE pdo.id_pergunta = r_delete.id_pergunta 
        AND pdo.escopo = 'turma'
  )
ORDER BY p.label;
