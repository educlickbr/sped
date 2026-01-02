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
    -- Verifica se existe alguma resposta nula ou vazia no JSON recebido
    SELECT to_jsonb(r)
    INTO v_resposta_invalida
    FROM jsonb_to_recordset(p_respostas) AS r(id_pergunta text, resposta text)
    WHERE r.resposta IS NULL OR trim(r.resposta) = ''
    LIMIT 1;

    IF v_resposta_invalida IS NOT NULL THEN
        RETURN jsonb_build_object(
            'sucesso', false,
            'mensagem', 'Não é permitido salvar respostas vazias ou nulas.',
            'dado_invalido', v_resposta_invalida
        );
    END IF;

    -------------------------------------------------------------------
    -- 1. Resolver user_expandido_id
    -------------------------------------------------------------------
    
    -- Caso 1: vier user_expandido_id explícito
    IF p_user_expandido_id IS NOT NULL THEN
        v_user_expandido_id := p_user_expandido_id;

    -- Caso 2: usar p_id_usuario (auth.users)
    ELSIF p_id_usuario IS NOT NULL THEN
        SELECT ue.id
        INTO v_user_expandido_id
        FROM public.user_expandido ue
        WHERE ue.user_id = p_id_usuario
        LIMIT 1;

        IF v_user_expandido_id IS NULL THEN
            RETURN jsonb_build_object(
                'sucesso', false,
                'mensagem', 'Usuário expandido não encontrado para o p_id_usuario informado.'
            );
        END IF;

    ELSE
        RETURN jsonb_build_object(
            'sucesso', false,
            'mensagem', 'É necessário informar p_id_usuario ou p_user_expandido_id.'
        );
    END IF;

    -------------------------------------------------------------------
    -- 2. Persistência com Lógica de Escopo
    -------------------------------------------------------------------
    BEGIN
        DECLARE
            v_area text; -- Ajustado para text para evitar erro de tipo inexistente
        BEGIN
            -- 2.1 Descobrir Área da Turma (se houver)
            IF p_id_turma IS NOT NULL THEN
                SELECT c.area INTO v_area
                FROM public.turmas t
                JOIN public.curso c ON c.id = t.id_curso
                WHERE t.id = p_id_turma;
            END IF;

            -- 2.2 Preparar Dados com Lógica da RAINHA (PDO)
            --     Decide se o id_turma será gravado ou se será forçado NULL (Global)
            --     MUDANÇA: Verifica se JÁ EXISTE resposta global para priorizar a consistência.
            CREATE TEMP TABLE tmp_respostas_to_save ON COMMIT DROP AS
            WITH raw_inputs AS (
                SELECT 
                    (r.id_pergunta)::uuid               AS id_pergunta,
                    r.resposta,
                    NULLIF(r.nome_arquivo_original, '') AS arquivo_original
                FROM jsonb_to_recordset(p_respostas) AS r(
                    id_pergunta text,
                    resposta text,
                    nome_arquivo_original text
                )
            ),
            existing_global AS (
                -- Busca perguntas que este usuário JÁ respondeu GLOBALMENTE (sem turma)
                -- Isso evita criar duplicatas (User+Pergunta+Turma) se já existe (User+Pergunta+NULL)
                SELECT r.id_pergunta 
                FROM public.respostas r
                WHERE r.user_expandido_id = v_user_expandido_id
                  AND r.id_turma IS NULL
                  AND r.id_pergunta IN (SELECT id_pergunta FROM raw_inputs)
            ),
            config_rainha AS (
                 SELECT 
                    ri.*,
                    COALESCE(p.tipo, 'texto') AS tipo_resposta,
                    CASE 
                        -- REGRA 1: Se p_id_turma é NULO, é sempre Global (prioridade máxima de input)
                        WHEN p_id_turma IS NULL THEN NULL 
                        
                        -- REGRA 2: Consultar a RAINHA (PDO) - Prioridade sobre histórico
                        -- Se o escopo for AREA -> Força NULL (Global)
                        WHEN pdo.escopo = 'area' THEN NULL
                        
                        -- Se o escopo for TURMA -> Usa o ID da Turma
                        WHEN pdo.escopo = 'turma' THEN p_id_turma
                        
                        -- REGRA 3: Fallback (PDO não encontrada/indefinida)
                        -- Se JÁ existe resposta global, MANTÉM global (evita duplicatas para perguntas como 'Idade' que perderam o PDO)
                        WHEN eg.id_pergunta IS NOT NULL THEN NULL

                        -- Fallback final: Assume o que veio no parametro
                        ELSE p_id_turma 
                    END AS final_id_turma
                 FROM raw_inputs ri
                 LEFT JOIN public.perguntas p ON p.id = ri.id_pergunta
                 LEFT JOIN public.processo_documentos_obrigatorios pdo 
                    ON pdo.id_pergunta = ri.id_pergunta
                    AND (
                         -- Tenta match hibrido para achar a config
                         (pdo.id_turma = p_id_turma) 
                         OR 
                         (pdo.id_turma IS NULL AND pdo.id_area = v_area::tipo_area)
                    )
                 LEFT JOIN existing_global eg ON eg.id_pergunta = ri.id_pergunta
                 -- DISTINCT ON para evitar duplicação se houver multiplas configs
            )
            SELECT DISTINCT ON (id_pergunta) * FROM config_rainha;

            ---------------------------------------------------------------
            -- 2.3 Executar Salva em Dois Lotes (devido aos índices parciais)
            ---------------------------------------------------------------

            -- LOTE 1: RESPOSTAS GLOBAIS (id_turma IS NULL)
            INSERT INTO public.respostas (
                user_expandido_id,
                id_usuario,
                id_pergunta,
                id_turma,
                resposta,
                arquivo_original,
                tipo_resposta,
                criado_em,
                atualizado_em
            )
            SELECT 
                v_user_expandido_id,
                p_id_usuario,
                id_pergunta,
                NULL, -- Força NULL explicitamente
                resposta,
                arquivo_original,
                tipo_resposta,
                NOW(),
                NULL
            FROM tmp_respostas_to_save
            WHERE final_id_turma IS NULL
            ON CONFLICT (user_expandido_id, id_pergunta) WHERE id_turma IS NULL
            DO UPDATE SET
                resposta         = EXCLUDED.resposta,
                arquivo_original = EXCLUDED.arquivo_original,
                tipo_resposta    = EXCLUDED.tipo_resposta,
                atualizado_em    = NOW(),
                id_usuario       = EXCLUDED.id_usuario;

            -- LOTE 2: RESPOSTAS DE TURMA (id_turma IS NOT NULL)
            INSERT INTO public.respostas (
                user_expandido_id,
                id_usuario,
                id_pergunta,
                id_turma,
                resposta,
                arquivo_original,
                tipo_resposta,
                criado_em,
                atualizado_em
            )
            SELECT 
                v_user_expandido_id,
                p_id_usuario,
                id_pergunta,
                final_id_turma, -- Usa o ID calculado
                resposta,
                arquivo_original,
                tipo_resposta,
                NOW(),
                NULL
            FROM tmp_respostas_to_save
            WHERE final_id_turma IS NOT NULL
            ON CONFLICT (user_expandido_id, id_pergunta, id_turma) WHERE id_turma IS NOT NULL
            DO UPDATE SET
                resposta         = EXCLUDED.resposta,
                arquivo_original = EXCLUDED.arquivo_original,
                tipo_resposta    = EXCLUDED.tipo_resposta,
                atualizado_em    = NOW(),
                id_usuario       = EXCLUDED.id_usuario;

        END;

        -- Retorno de Sucesso
        RETURN jsonb_build_object(
            'sucesso', true,
            'mensagem', 'Respostas salvas com sucesso.'
        );

    EXCEPTION WHEN OTHERS THEN
        -- Retorno de Erro Genérico (capturando mensagem do banco)
        RETURN jsonb_build_object(
            'sucesso', false,
            'mensagem', 'Erro ao salvar respostas: ' || SQLERRM
        );
    END;
END;
$BODY$;

ALTER FUNCTION public.salvar_respostas_usuario(p_id_usuario uuid, p_respostas jsonb, p_user_expandido_id uuid DEFAULT NULL::uuid, p_id_turma uuid DEFAULT NULL::uuid)
    OWNER TO postgres;
