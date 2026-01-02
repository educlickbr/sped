-- 1. Count items to be deleted
--SELECT COUNT(*) FROM diario_controle_sync WHERE status = 'concluido';

-- 2. Delete items
DELETE FROM diario_controle_sync WHERE status = 'ignorado';
