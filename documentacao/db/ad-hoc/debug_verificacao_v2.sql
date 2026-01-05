-- Debug para verificar por que o bloco_destino 'dados_socio_economicos' não é encontrado
-- Parametros usados:
-- p_area: 'extensao'
-- p_id_turma: '6c23c7d4-d9b8-4c76-a666-1e4a6e3e0afb'
-- p_bloco: 'dados_socio_economicos'

SELECT 
    id,
    bloco,
    escopo,
    id_area,
    id_turma,
    ordem_bloco,
    tipo_processo,
    tipo_candidatura
FROM processo_documentos_obrigatorios
WHERE bloco::text = 'dados_socio_economicos'
  AND (
        (escopo = 'area'  AND id_area  = 'extensao')
     OR (escopo = 'turma' AND id_turma = '6c23c7d4-d9b8-4c76-a666-1e4a6e3e0afb')
  );
