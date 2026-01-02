-- 1. PREVIEW DELETE: Serão deletadas (pois já existe Global)
SELECT 'TO_DELETE' as acao, COUNT(*) as qtd, array_agg(id) as ids_amostra
FROM public.respostas r_wrong
WHERE r_wrong.id_turma IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 
      FROM public.processo_documentos_obrigatorios pdo
      WHERE pdo.id_pergunta = r_wrong.id_pergunta 
        AND pdo.escopo = 'turma'
  )
  AND EXISTS (
      SELECT 1 
      FROM public.respostas r_global
      WHERE r_global.user_expandido_id = r_wrong.user_expandido_id
        AND r_global.id_pergunta = r_wrong.id_pergunta
        AND r_global.id_turma IS NULL
  )

UNION ALL

-- 2. PREVIEW UPDATE: Serão convertidas para Global (id_turma = NULL)
SELECT 'TO_UPDATE' as acao, COUNT(*) as qtd, array_agg(id) as ids_amostra
FROM public.respostas r
WHERE r.id_turma IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 
      FROM public.processo_documentos_obrigatorios pdo
      WHERE pdo.id_pergunta = r.id_pergunta 
        AND pdo.escopo = 'turma'
  )
  AND NOT EXISTS ( -- Garante que não cai no caso acima
      SELECT 1 
      FROM public.respostas r_global
      WHERE r_global.user_expandido_id = r.user_expandido_id
        AND r_global.id_pergunta = r.id_pergunta
        AND r_global.id_turma IS NULL
  );

-- Detalhes (Opcional - Remova comentários se quiser ver as linhas)
/*
SELECT 
    r.user_expandido_id, 
    r.id_pergunta, 
    p.label, 
    CASE 
        WHEN rg.id IS NOT NULL THEN 'SERA DELETADO (Duplicata)' 
        ELSE 'SERA ATUALIZADO (Correcao de Escopo)' 
    END as status
FROM public.respostas r
JOIN public.perguntas p ON p.id = r.id_pergunta
LEFT JOIN public.respostas rg 
    ON rg.user_expandido_id = r.user_expandido_id
    AND rg.id_pergunta = r.id_pergunta
    AND rg.id_turma IS NULL
WHERE r.id_turma IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 
      FROM public.processo_documentos_obrigatorios pdo
      WHERE pdo.id_pergunta = r.id_pergunta 
        AND pdo.escopo = 'turma'
  );
*/
