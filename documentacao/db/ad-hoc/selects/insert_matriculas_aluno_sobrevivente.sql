INSERT INTO public.matriculas (
    id_aluno,
    id_turma,
    status,
    declaracao_matricula
) VALUES 
(
    '4211504f-fa89-4b04-ba27-b4eed3af78e8', -- Aluno Sobrevivente
    'b2ddc239-b87c-43d0-8495-5e6980b353f7', -- Turma 1
    'Ativo',
    false
),
(
    '4211504f-fa89-4b04-ba27-b4eed3af78e8', -- Aluno Sobrevivente
    '9d482ec4-bc13-4f9f-a701-8bf424db2026', -- Turma 2
    'Ativo',
    false
)
ON CONFLICT (id_aluno, id_turma) DO NOTHING;
