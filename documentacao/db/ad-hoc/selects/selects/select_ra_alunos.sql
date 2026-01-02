SELECT id,
       id_aluno,
       ra,
       ra_legado,
       ano_ingresso,
       semestre_ingresso,
       ano_semestre_ingresso,
       codigo_lista_ano_semestre,
       milhar,
       criado_em,
       atualizado_em
FROM public.ra_alunos
WHERE ano_semestre_ingresso = '26Is'
LIMIT 1000;