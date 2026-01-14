CREATE OR REPLACE FUNCTION public.nxt_verificar_matricula_ativa(p_auth_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_ativo boolean;
    v_user_expandido_id uuid;
BEGIN
    -- Obter ID do user_expandido
    SELECT id INTO v_user_expandido_id
    FROM public.user_expandido
    WHERE user_id = p_auth_id;

    IF v_user_expandido_id IS NULL THEN
        RETURN jsonb_build_object('ativa', false, 'mensagem', 'Usuário não encontrado.');
    END IF;

    -- Verificar matricula ativa em curso regular
    -- Critérios:
    -- 1. Status da matrícula deve ser 'Ativa'
    -- 2. Área do curso deve ser 'regulares' (normalizada)
    -- 3. Turma deve ser '26Is' OU data fim do curso maior que hoje
    SELECT EXISTS (
        SELECT 1
        FROM public.matriculas m
        JOIN public.turmas t ON m.id_turma = t.id
        JOIN public.curso c ON t.id_curso = c.id
        WHERE m.id_aluno = v_user_expandido_id
          AND m.status = 'Ativa'
          AND public.normalizar_texto(c.area) = 'regulares'
          AND (
              t.cod_turma = '26Is'
              OR t.dt_fim_curso > CURRENT_DATE
          )
    ) INTO v_ativo;

    IF v_ativo THEN
        RETURN jsonb_build_object('ativa', true, 'mensagem', 'Matrícula ativa encontrada para o curso regular.');
    ELSE
        RETURN jsonb_build_object('ativa', false, 'mensagem', 'Nenhuma matrícula ativa encontrada para cursos regulares.');
    END IF;
END;
$$;
