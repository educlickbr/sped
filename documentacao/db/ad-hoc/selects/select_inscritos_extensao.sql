-- Select para buscar inscritos (processos) na área de Extensão
-- Organizado por blocos e ordem definidos no formulário
-- Variáveis para substituição:
-- :ano_semestre -> Ano e Semestre (ex: '26Is')

SELECT 
    ue.nome,
    ue.sobrenome,
    ue.email,
    t.nome_curso as turma_inscrita,
    -- CPF (20467206-19d9-4bb9-8a54-e6625f101282)
    (SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '20467206-19d9-4bb9-8a54-e6625f101282' ORDER BY r.criado_em DESC LIMIT 1) as "CPF",
    -- RG (29a21c21-b102-434e-a05b-08cc5e871de7)
    (SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '29a21c21-b102-434e-a05b-08cc5e871de7' ORDER BY r.criado_em DESC LIMIT 1) as "RG"
    -- Bloco: dados_pessoais | Ordem: 4
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '78e5931f-9f8f-4f9b-bbb0-36041c404c4e' ORDER BY r.criado_em DESC LIMIT 1) as "Mídias Sociais"
    -- Bloco: dados_pessoais | Ordem: 5
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = 'e31a53ea-a7d3-49d2-8241-282ac8be7913' ORDER BY r.criado_em DESC LIMIT 1) as "Mini Bio: Fale um pouco da sua trajetória"
    -- Bloco: dados_pessoais | Ordem: 6
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '8925bdc2-538a-408d-bd34-fb64b2638621' ORDER BY r.criado_em DESC LIMIT 1) as "Data de Nascimento"
    -- Bloco: dados_pessoais | Ordem: 7
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '57ea34cf-27ed-460d-b27c-244f49d36d62' ORDER BY r.criado_em DESC LIMIT 1) as "Idade"
    -- Bloco: dados_pessoais | Ordem: 8
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '93642773-5a9c-4ada-8356-21e7e7bb9eda' ORDER BY r.criado_em DESC LIMIT 1) as "Telefone Celular"
    -- Bloco: dados_pessoais | Ordem: 9
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '2f53dcc3-4429-457c-bcb1-6487bc3ab5af' ORDER BY r.criado_em DESC LIMIT 1) as "Telefone Fixo"
    -- Bloco: dados_pessoais | Ordem: 10
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = 'c95e476a-c4dc-4520-badd-d7392b0aeab7' ORDER BY r.criado_em DESC LIMIT 1) as "Sua Foto"
    -- Bloco: responsavel_legal | Ordem: 1
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '80a168f7-f57d-4c1e-87b0-57cd758c417c' ORDER BY r.criado_em DESC LIMIT 1) as "Nome do Responsável Legal"
    -- Bloco: responsavel_legal | Ordem: 2
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '731fcb9a-0636-418a-bb7d-5c4fce3647aa' ORDER BY r.criado_em DESC LIMIT 1) as "Sobrenome do Responsável Legal"
    -- Bloco: responsavel_legal | Ordem: 3
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '79fa2e96-04eb-4bab-8d9f-5046267d4160' ORDER BY r.criado_em DESC LIMIT 1) as "CPF do responsável legal"
    -- Bloco: responsavel_legal | Ordem: 4
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '4063e63c-7369-42aa-8744-018028d765e5' ORDER BY r.criado_em DESC LIMIT 1) as "Telefone do responsável legal"
    -- Bloco: responsavel_legal | Ordem: 5
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '34652bc7-2f46-49c9-beb7-77c353754662' ORDER BY r.criado_em DESC LIMIT 1) as "E-mail do responsável legal"
    -- Bloco: responsavel_legal | Ordem: 6
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '172bf4c5-7609-40d0-a805-d5291fdec84a' ORDER BY r.criado_em DESC LIMIT 1) as "Documento Responsável Legal"
    -- Bloco: endereco | Ordem: 1
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '142a7c41-fe7c-4dc9-9d5c-d7f407403dc9' ORDER BY r.criado_em DESC LIMIT 1) as "Naturalidade (cidade onde nasceu)"
    -- Bloco: endereco | Ordem: 2
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '571ca637-9123-449d-9e04-b51d09f2836e' ORDER BY r.criado_em DESC LIMIT 1) as "CEP"
    -- Bloco: endereco | Ordem: 3
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = 'e1021ed4-b981-4984-afe9-52e62377c4a6' ORDER BY r.criado_em DESC LIMIT 1) as "Cidade"
    -- Bloco: endereco | Ordem: 4
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '6f0e18b1-f519-46c5-98d2-7c05e6ebb135' ORDER BY r.criado_em DESC LIMIT 1) as "Endereço"
    -- Bloco: endereco | Ordem: 5
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '62f5fd50-fabe-49a6-84a7-f2a0296a6f48' ORDER BY r.criado_em DESC LIMIT 1) as "Número"
    -- Bloco: endereco | Ordem: 6
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '6a2dc4d0-5994-42fb-b0bf-66f79a227c98' ORDER BY r.criado_em DESC LIMIT 1) as "Complemento"
    -- Bloco: endereco | Ordem: 7
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = 'f1d674d0-f8c5-43bf-a42c-073a5de9419e' ORDER BY r.criado_em DESC LIMIT 1) as "Estado"
    -- Bloco: endereco | Ordem: 8
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '5c4bc372-867d-471b-86da-52a437146c1e' ORDER BY r.criado_em DESC LIMIT 1) as "País"
    -- Bloco: endereco | Ordem: 9
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '95e3d2c9-7507-4c53-84da-4c71bdd8726f' ORDER BY r.criado_em DESC LIMIT 1) as "Comprovante de Endereço"
    -- Bloco: dados_socio_economicos | Ordem: 1
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '444ae763-4fba-4253-8e56-6d43dde48b89' ORDER BY r.criado_em DESC LIMIT 1) as "Profissão"
    -- Bloco: dados_socio_economicos | Ordem: 2
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '9670c817-5db6-4055-8fc9-04cc15d6cd3e' ORDER BY r.criado_em DESC LIMIT 1) as "Cor/raça"
    -- Bloco: dados_socio_economicos | Ordem: 3
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '25edf1cb-ed2f-4ae2-a85d-ef5c6f0af8ea' ORDER BY r.criado_em DESC LIMIT 1) as "Identidade de gênero"
    -- Bloco: dados_socio_economicos | Ordem: 4
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '32b1a387-a2a9-4f79-af30-d32026af64fe' ORDER BY r.criado_em DESC LIMIT 1) as "Nome Social"
    -- Bloco: dados_socio_economicos | Ordem: 5
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '84f68e21-cf23-4a01-8d04-3f4c6777da11' ORDER BY r.criado_em DESC LIMIT 1) as "Nacionalidade"
    -- Bloco: dados_socio_economicos | Ordem: 6
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '70e46597-3dcd-4aad-aaab-5fd2693cd53c' ORDER BY r.criado_em DESC LIMIT 1) as "Formação escolar"
    -- Bloco: dados_socio_economicos | Ordem: 7
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '98d09feb-ec9a-4a30-882d-7de8099c153f' ORDER BY r.criado_em DESC LIMIT 1) as "Renda familiar per capita"
    -- Bloco: pcd | Ordem: 1
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = 'eae93308-1e4d-4c67-9c53-c9abf6a31eaf' ORDER BY r.criado_em DESC LIMIT 1) as "É PCD?"
    -- Bloco: pcd | Ordem: 2
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '94dc7bab-65f7-441f-a49f-78b06e15894b' ORDER BY r.criado_em DESC LIMIT 1) as "Especifique"
    -- Bloco: pcd | Ordem: 3
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = 'de76ebe6-38d2-44e1-a112-ee64ad604c4f' ORDER BY r.criado_em DESC LIMIT 1) as "Se sim, por favor anexe o laudo médico"
    -- Bloco: pcd | Ordem: 4
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '25ea2ab7-c0da-441d-8a10-bf724523c5a1' ORDER BY r.criado_em DESC LIMIT 1) as "Precisa de algum recurso de acessibilidade? Em caso posit..."
    -- Bloco: sobre_curso | Ordem: 1
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '91459419-4fc8-4d10-9b27-1135ffe71c2c' ORDER BY r.criado_em DESC LIMIT 1) as "Você veio pela parceria com outros municípios de São Paul..."
    -- Bloco: sobre_curso | Ordem: 2
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = 'a5d2bbde-2622-4914-a9e8-5e4fe16e06cf' ORDER BY r.criado_em DESC LIMIT 1) as "Por que você deseja participar deste curso?"
    -- Bloco: sobre_curso | Ordem: 3
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = 'ba89d715-ae19-425b-9915-f0d9da22938b' ORDER BY r.criado_em DESC LIMIT 1) as "Como você ficou sabendo deste curso?"
    -- Bloco: sobre_curso | Ordem: 4
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '0ac80dca-2ca8-4d3e-918f-c344e4d8ce28' ORDER BY r.criado_em DESC LIMIT 1) as "Deseja receber informações sobre as atividades da escola?"
    -- Bloco: sobre_curso | Ordem: 5
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = 'ad205fed-e981-45a5-af95-ad8b9ea559b6' ORDER BY r.criado_em DESC LIMIT 1) as "Já participou de algum curso na Extensão Cultural da SPED..."
    -- Bloco: prontidao | Ordem: 1
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = 'e0dee9ed-6a46-406d-8b2e-9d8f7fb70338' ORDER BY r.criado_em DESC LIMIT 1) as "Algum médico já disse que você possui algum problema de c..."
    -- Bloco: prontidao | Ordem: 2
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = 'd81baff3-a392-422f-a162-c33abddd4620' ORDER BY r.criado_em DESC LIMIT 1) as "Você sente dores no peito quando pratica atividade física?"
    -- Bloco: prontidao | Ordem: 3
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '9ea0d6e0-04cf-4ada-9905-14966d7b6cad' ORDER BY r.criado_em DESC LIMIT 1) as "No último mês, você sentiu dores no peito quando praticou..."
    -- Bloco: prontidao | Ordem: 4
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '04f974be-6f60-4c40-a9ed-dd8b8d9990fd' ORDER BY r.criado_em DESC LIMIT 1) as "Você apresenta desequilíbrio devido à tontura e/ou perda ..."
    -- Bloco: prontidao | Ordem: 5
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '15253824-2e07-48af-a2ad-b865d4c7a6b1' ORDER BY r.criado_em DESC LIMIT 1) as "Você possui algum problema ósseo ou articular que poderia..."
    -- Bloco: prontidao | Ordem: 6
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = 'e667d832-2104-4313-b67e-476c4bea7b32' ORDER BY r.criado_em DESC LIMIT 1) as "Você toma atualmente algum medicamento para pressão arter..."
    -- Bloco: prontidao | Ordem: 7
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '48299c6b-4726-49af-88c0-914b83e78957' ORDER BY r.criado_em DESC LIMIT 1) as "Sabe de alguma outra razão pela qual você não deve pratic..."
    -- Bloco: prontidao | Ordem: 8
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '7b5d6918-85da-419a-94af-ab74dbb5bc1f' ORDER BY r.criado_em DESC LIMIT 1) as "Possui alguma outra condição de saúde física ou psicológi..."
    -- Bloco: prontidao | Ordem: 9
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '897ef74b-b061-4a8c-b7cf-feabe5fdbcef' ORDER BY r.criado_em DESC LIMIT 1) as "Toma algum remédio controlado?"
    -- Bloco: documentos | Ordem: 1
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '20467206-19d9-4bb9-8a54-e6625f101282' ORDER BY r.criado_em DESC LIMIT 1) as "CPF"
    -- Bloco: documentos | Ordem: 2
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '29a21c21-b102-434e-a05b-08cc5e871de7' ORDER BY r.criado_em DESC LIMIT 1) as "RG"
    -- Bloco: documentos | Ordem: 3
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '07984444-cb05-4be5-a5b8-59eb9e2c5997' ORDER BY r.criado_em DESC LIMIT 1) as "CPF"
    -- Bloco: documentos | Ordem: 4
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '538a2c3d-e45f-42b0-b899-91ce9fd751b9' ORDER BY r.criado_em DESC LIMIT 1) as "RG"
    -- Bloco: documentos | Ordem: 5
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '5902e39e-26bb-40a3-b117-15799c0bb231' ORDER BY r.criado_em DESC LIMIT 1) as "Currículo Resumido"
    -- Bloco: documentos | Ordem: 6
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '09bf6de0-10ef-4d54-81ba-9074a2e28535' ORDER BY r.criado_em DESC LIMIT 1) as "Carta de intenção do(a) candidato(a), de 1000 a 2000 cara..."
    -- Bloco: documentos | Ordem: 7
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = '6e7ba1c1-1822-43e9-a93d-06325bce7a0b' ORDER BY r.criado_em DESC LIMIT 1) as "Cópia do comprovante de matrícula do ensino regular (para..."
    -- Bloco: documentos | Ordem: 8
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = 'ef92aa9b-eed1-4009-adba-197719f4f0f3' ORDER BY r.criado_em DESC LIMIT 1) as "Link para um vídeo de até 1 minuto."
    -- Bloco: aceite | Ordem: 1
    ,(SELECT r.resposta FROM public.respostas r WHERE (r.user_expandido_id = ue.id OR r.id_usuario = ue.user_id) AND r.id_pergunta = 'cc164282-0822-4ba1-9dc1-c0db537ebb77' ORDER BY r.criado_em DESC LIMIT 1) as "Ao realizar esta inscrição o(a) candidato(a) ou o(a) resp..."
FROM 
    public.processos proc
JOIN 
    public.user_expandido ue ON proc.user_expandido_id = ue.id
JOIN 
    public.turmas t ON proc.turma_id = t.id
WHERE 
    t.ano_semestre = '26Is' -- Substituir :ano_semestre
    AND public.normalizar_texto(t.area_curso) = 'extensao'
    AND proc.tipo_processo = 'seletivo'
    AND proc.tipo_candidatura = 'estudante'
ORDER BY 
    t.nome_curso, ue.nome;
