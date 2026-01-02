INSERT INTO public.processo_documentos_obrigatorios (
    id,
    escopo,
    id_area,
    id_curso,
    id_turma,
    id_pergunta,
    obrigatorio,
    observacoes,
    tipo_processo,
    bloco,
    ordem,
    leitura,
    tipo_candidatura,
    largura_coluna,
    altura_coluna,
    largura,
    altura,
    depende,
    depende_de,
    valor_depende,
    pergunta_gatilho,
    valor_gatilho,
    ordem_bloco
) VALUES (
    '87ecae95-e662-4f8d-82e0-27dd1669d3a2', -- id
    'area'::escopo_processo,                -- escopo
    'regulares'::tipo_area,                 -- id_area
    NULL,                                   -- id_curso
    NULL,                                   -- id_turma
    'e31a53ea-a7d3-49d2-8241-282ac8be7913', -- id_pergunta
    true,                                   -- obrigatorio
    NULL,                                   -- observacoes
    'matricula'::tipo_processo,             -- tipo_processo
    'dados_pessoais'::bloco_pergunta,       -- bloco
    15,                                     -- ordem
    false,                                  -- leitura
    'estudante'::tipo_candidatura,          -- tipo_candidatura
    'simples'::largura_coluna_tipo,         -- largura_coluna
    'simples'::altura_coluna_tipo,          -- altura_coluna
    2,                                      -- largura
    36,                                     -- altura
    false,                                  -- depende
    NULL,                                   -- depende_de
    NULL,                                   -- valor_depende
    false,                                  -- pergunta_gatilho
    NULL,                                   -- valor_gatilho
    1                                       -- ordem_bloco
);
