-- 1. DELETE: Remove respostas com id_turma indevido SE já existir uma versão Global para o mesmo usuário/pergunta
-- Isso evita o erro de "duplicate key" ao tentar atualizar para NULL
DELETE FROM public.respostas r_wrong
WHERE r_wrong.id_turma IS NOT NULL
  -- Confirma que NÃO deveria ser turma (Rainha)
  AND NOT EXISTS (
      SELECT 1 
      FROM public.processo_documentos_obrigatorios pdo
      WHERE pdo.id_pergunta = r_wrong.id_pergunta 
        AND pdo.escopo = 'turma'
  )
  -- E confirma que JÁ EXISTE uma resposta global (então a que estamos deletando é duplicata inútil)
  AND EXISTS (
      SELECT 1 
      FROM public.respostas r_global
      WHERE r_global.user_expandido_id = r_wrong.user_expandido_id
        AND r_global.id_pergunta = r_wrong.id_pergunta
        AND r_global.id_turma IS NULL
  );

-- 2. UPDATE: Converte para Global as restantes (que não tinham versão global ainda)
UPDATE public.respostas r
SET id_turma = NULL,
    atualizado_em = NOW()
WHERE r.id_turma IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 
      FROM public.processo_documentos_obrigatorios pdo
      WHERE pdo.id_pergunta = r.id_pergunta 
        AND pdo.escopo = 'turma'
  );