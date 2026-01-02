-- Remove o usuário duplicado da tabela user_expandido
-- ATENÇÃO: Certifique-se de que todas as referências (diario, matriculas, financeiro, etc.) 
-- foram transferidas para o usuário 'sobrevivente' ou removidas ANTES de executar este comando.
-- Caso contrário, o comando falhará devido a restrições de chave estrangeira (FK).

DELETE FROM public.user_expandido
WHERE id = 'ID_DO_ALUNO_DUPLICADO';
