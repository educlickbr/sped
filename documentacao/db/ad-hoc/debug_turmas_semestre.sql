-- Verificando os dados das duas turmas da Beatriz para entender o filtro de Ano/Semestre
SELECT 
    id, 
    nome_curso, 
    area_curso, 
    ano_semestre, 
    id_curso
FROM public.turmas 
WHERE id IN (
    'f7b79d92-cf13-456b-9792-bb421a7279e4', -- Extensão?
    '3834456a-97ac-4858-9738-8a4d3e5991c7'  -- Regulares?
);
