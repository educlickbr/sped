-- Script para apagar respostas de arquivo com formato inválido
-- Mostra a contagem de itens apagados ao final

WITH deleted_rows AS (
    DELETE FROM respostas 
    WHERE tipo_resposta = 'arquivo'
      AND (
        resposta IS NULL 
        OR resposta !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.[a-z0-9]+$'
      )
    RETURNING id
)
SELECT COUNT(*) as total_apagados FROM deleted_rows;
