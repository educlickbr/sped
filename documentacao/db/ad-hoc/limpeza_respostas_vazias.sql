-- 1. Ver os itens (Amostra de 100 itens)
--SELECT * FROM respostas 
--WHERE resposta IS NULL OR TRIM(resposta) = ''
--LIMIT 100;

-- 2. Contagem total
SELECT COUNT(*) FROM respostas 
WHERE resposta IS NULL OR TRIM(resposta) = '';

-- 3. Deletar os itens (Remova o comentário para executar)
 --DELETE FROM respostas WHERE resposta IS NULL OR TRIM(resposta) = '';
