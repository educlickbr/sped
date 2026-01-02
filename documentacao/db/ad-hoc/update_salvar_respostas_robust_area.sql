DROP FUNCTION public.salvar_respostas_usuario;
CREATE OR REPLACE FUNCTION public.salvar_respostas_usuario(
	p_id_usuario uuid,
	p_respostas jsonb,
	p_user_expandido_id uuid DEFAULT NULL::uuid,
	p_id_turma uuid DEFAULT NULL::uuid)
    RETURNS jsonb
    LANGUAGE plpgsql
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    v_user_expandido_id uuid;
    v_resposta_invalida jsonb;
BEGIN
    -------------------------------------------------------------------
    -- 0. Validação de Entrada (NULL ou Vazio)
    -------------------------------------------------------------------
    SELECT to_jsonb(r) INTO v_resposta_invalida
    FROM jsonb_to_recordset(p_respostas) AS r(id_pergunta text, resposta text)
    WHERE r.resposta IS NULL OR trim(r.resposta) = '';

    IF v_resposta_invalida IS NOT NULL THEN
        RETURN jsonb_build_object('sucesso', false, 'mensagem', 'Não é permitido salvar respostas vazias ou nulas.', 'dado_invalido', v_resposta_invalida);
    END IF;

    -------------------------------------------------------------------
    -- 1. Resolver user_expandido_id
    -------------------------------------------------------------------
    IF p_user_expandido_id IS NOT NULL THEN
        v_user_expandido_id := p_user_expandido_id;
    ELSIF p_id_usuario IS NOT NULL THEN
        SELECT ue.id INTO v_user_expandido_id FROM public.user_expandido ue WHERE ue.user_id = p_id_usuario LIMIT 1;
        IF v_user_expandido_id IS NULL THEN
            RETURN jsonb_build_object('sucesso', false, 'mensagem', 'Usuário expandido não encontrado.');
        END IF;
    ELSE
        RETURN jsonb_build_object('sucesso', false, 'mensagem', 'Identificação do usuário necessária.');
    END IF;

    -------------------------------------------------------------------
    -- 2. Lógica Estrita da Rainha (PDO)
    -------------------------------------------------------------------
    BEGIN
        DECLARE
            v_area_turma text;
        BEGIN
            -- 2.1 Descobrir Área da Turma para o contexto da Rainha
            IF p_id_turma IS NOT NULL THEN
                SELECT c.area::text INTO v_area_turma -- Force cast to text here
                FROM public.turmas t
                JOIN public.curso c ON c.id = t.id_curso
                WHERE t.id = p_id_turma;
            END IF;

            -- 2.2 Preparar Lote de Salva Decidindo o ID_TURMA final
            CREATE TEMP TABLE tmp_save_final ON COMMIT DROP AS
            WITH raw_inputs AS (
                SELECT 
                    (r.id_pergunta)::uuid AS id_pergunta,
                    r.resposta,
                    NULLIF(r.nome_arquivo_original, '') AS arquivo_original
                FROM jsonb_to_recordset(p_respostas) AS r(id_pergunta text, resposta text, nome_arquivo_original text)
            ),
            scope_decision AS (
                SELECT 
                    ri.*,
                    COALESCE(p.tipo, 'texto') AS tipo_resposta,
                    
                    -- AQUI ESTÁ A LÓGICA PEDIDA:
                    -- "A tabela processos_documentos_obrigatorios é quem diz"
                    CASE 
                        -- Se a Rainha diz que é TURMA para este contexto -> Salva com p_id_turma
                        WHEN pdo.escopo = 'turma' THEN p_id_turma
                        
                        -- Qualquer outro caso (Area, Curso, Não achou, p_id_turma nulo) -> Salva GLOBAL (NULL)
                        ELSE NULL 
                    END AS final_id_turma
                FROM raw_inputs ri
                LEFT JOIN public.perguntas p ON p.id = ri.id_pergunta
                LEFT JOIN public.processo_documentos_obrigatorios pdo 
                   ON pdo.id_pergunta = ri.id_pergunta
                   -- Match de Contexto:
                   -- 1. Existe config específica para a Turma?
                   -- 2. OU Existe config para a Área (template) e sem turma específica definida?
                   AND (
                       (pdo.id_turma = p_id_turma)
                       OR 
                       (
                           pdo.id_turma IS NULL 
                           AND v_area_turma IS NOT NULL 
                           -- ROBUST FIX: Usar normalizacao para comparar Area
                           AND public.normalizar_texto(pdo.id_area::text) = public.normalizar_texto(v_area_turma)
                       )
                   )
                
                -- Se houver ambiguidade (ex: configs de Área e Turma ao mesmo tempo),
                -- a ordenação deve garantir que a regra mais específica (turma) ganhe.
                -- (Isso depende de como a tabela está populada, mas o LEFT JOIN pega tudo)
            )
            -- DISTINCT ON para desambiguar caso venha mais de um registro do PDO
            -- Se vier um 'turma' e um 'area', priorizamos 'turma' na ordem abaixo
            SELECT DISTINCT ON (id_pergunta) * 
            FROM scope_decision
            ORDER BY id_pergunta, 
                     (CASE WHEN final_id_turma IS NOT NULL THEN 1 ELSE 2 END); -- Prioriza quem resolveu ID de turma

            ---------------------------------------------------------------
            -- 2.3 Executar Upserts (Separados para evitar erro de sintaxe)
            ---------------------------------------------------------------

            -- LOTE 1: GLOBAIS (final_id_turma IS NULL)
            INSERT INTO public.respostas (
                user_expandido_id, id_usuario, id_pergunta, id_turma,
                resposta, arquivo_original, tipo_resposta, criado_em, atualizado_em
            )
            SELECT 
                v_user_expandido_id, p_id_usuario, id_pergunta, NULL, 
                resposta, arquivo_original, tipo_resposta, NOW(), NULL
            FROM tmp_save_final
            WHERE final_id_turma IS NULL
            ON CONFLICT (user_expandido_id, id_pergunta) WHERE id_turma IS NULL
            DO UPDATE SET
                resposta         = EXCLUDED.resposta,
                arquivo_original = EXCLUDED.arquivo_original,
                tipo_resposta    = EXCLUDED.tipo_resposta,
                atualizado_em    = NOW(),
                id_usuario       = EXCLUDED.id_usuario;

            -- LOTE 2: TURMA (final_id_turma IS NOT NULL)
            INSERT INTO public.respostas (
                user_expandido_id, id_usuario, id_pergunta, id_turma,
                resposta, arquivo_original, tipo_resposta, criado_em, atualizado_em
            )
            SELECT 
                v_user_expandido_id, p_id_usuario, id_pergunta, final_id_turma,
                resposta, arquivo_original, tipo_resposta, NOW(), NULL
            FROM tmp_save_final
            WHERE final_id_turma IS NOT NULL
            ON CONFLICT (user_expandido_id, id_pergunta, id_turma) WHERE id_turma IS NOT NULL
            DO UPDATE SET
                resposta         = EXCLUDED.resposta,
                arquivo_original = EXCLUDED.arquivo_original,
                tipo_resposta    = EXCLUDED.tipo_resposta,
                atualizado_em    = NOW(),
                id_usuario       = EXCLUDED.id_usuario;

        END;

        RETURN jsonb_build_object('sucesso', true, 'mensagem', 'Respostas salvas com sucesso.');

    EXCEPTION WHEN OTHERS THEN
        RETURN jsonb_build_object('sucesso', false, 'mensagem', 'Erro ao salvar respostas: ' || SQLERRM);
    END;
END;
$BODY$;
