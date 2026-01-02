-- Seleciona e gera RAs para todas as matrículas de turmas '26Is'
-- A função gerar_ra_aluno_deterministico é idempotente (não duplica se já existir)

SELECT 
    m.id_aluno,
    ue.email,
    t.cod_turma,
    public.gerar_ra_aluno_deterministico(
        m.id_aluno, 
        '2026',           -- Ano derivado de '26Is'
        1::smallint,      -- Semestre derivado de '26Is'
        NULL
    ) as ra_gerado
FROM public.matriculas m
JOIN public.turmas t ON t.id = m.id_turma
JOIN public.user_expandido ue ON ue.id = m.id_aluno
WHERE t.ano_semestre = '26Is';
