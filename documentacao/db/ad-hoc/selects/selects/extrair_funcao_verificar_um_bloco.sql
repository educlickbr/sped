-- Extrair definicao da funcao interna _verificar_um_bloco
-- Execute este script para ver o codigo fonte da funcao que nao esta disponivel nos arquivos.

SELECT pg_get_functiondef('public._verificar_um_bloco'::regproc) as definicao_funcao;
