-- 1. Ver respostas do tipo 'arquivo' que NÃO seguem o formato UUID.extensao
SELECT 
    id,
    user_expandido_id,
    resposta as conteudo_atual,
    tipo_resposta,
    criado_em
FROM respostas 
WHERE tipo_resposta = 'arquivo'
  AND (
    resposta IS NULL 
    OR resposta !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.[a-z0-9]+$'
  )
LIMIT 1000;

-- 2. Contagem total de formatos inválidos
SELECT COUNT(*) 
FROM respostas 
WHERE tipo_resposta = 'arquivo'
  AND (
    resposta IS NULL 
    OR resposta !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.[a-z0-9]+$'
  );
