-- 1. Ver respostas que estão sem id_usuario, mas o usuário já tem vínculo com auth
SELECT 
    r.id as resposta_id,
    r.user_expandido_id,
    ue.nome,
    ue.email,
    ue.user_id as user_id_correto
FROM respostas r
JOIN user_expandido ue ON r.user_expandido_id = ue.id
WHERE r.id_usuario IS NULL 
  AND ue.user_id IS NOT NULL;

-- 2. Contagem total de casos
SELECT COUNT(*) 
FROM respostas r
JOIN user_expandido ue ON r.user_expandido_id = ue.id
WHERE r.id_usuario IS NULL 
  AND ue.user_id IS NOT NULL;

-- 3. (Opcional) Script para corrigir
-- UPDATE respostas r
-- SET id_usuario = ue.user_id
-- FROM user_expandido ue
-- WHERE r.user_expandido_id = ue.id
--   AND r.id_usuario IS NULL 
--   AND ue.user_id IS NOT NULL;
