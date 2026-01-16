CREATE OR REPLACE FUNCTION public.nxt_upsert_rematricula(p_id_user_expandido uuid, p_id_turma_atual uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_turma_atual RECORD;
    v_proximo_semestre TEXT;
    v_ano_atual INT;
    v_id_proxima_turma UUID;
    v_id_matricula UUID;
    v_existe_matricula BOOLEAN;
    v_nome_proxima_turma TEXT;
    v_turno_proxima_turma TEXT;
    v_nome_composto_proxima_turma TEXT;
    v_existe_matricula_destino BOOLEAN;
BEGIN
    -- 1. Verificar a matrícula deste usuário na turma informada
    SELECT EXISTS (
        SELECT 1 
        FROM public.matriculas 
        WHERE id_aluno = p_id_user_expandido 
          AND id_turma = p_id_turma_atual
    ) INTO v_existe_matricula;

    IF NOT v_existe_matricula THEN
        RETURN jsonb_build_object(
            'success', false, 
            'message', 'Aluno não possui matrícula ativa na turma informada.'
        );
    END IF;

    -- 2. Obter dados da turma atual
    SELECT * INTO v_turma_atual FROM public.turmas WHERE id = p_id_turma_atual;
    
    IF v_turma_atual IS NULL THEN
        RETURN jsonb_build_object(
            'success', false, 
            'message', 'Turma atual não encontrada.'
        );
    END IF;

    -- 3. Calcular o próximo semestre
    -- Lógica: Se termina em 'Is', muda para 'IIs'. Se termina em 'IIs', incrementa ano e muda para 'Is'.
    IF v_turma_atual.ano_semestre LIKE '%Is' AND v_turma_atual.ano_semestre NOT LIKE '%IIs' THEN
        v_proximo_semestre := REPLACE(v_turma_atual.ano_semestre, 'Is', 'IIs');
    ELSIF v_turma_atual.ano_semestre LIKE '%IIs' THEN
        -- Extrai a parte numérica do início
        v_ano_atual := (substring(v_turma_atual.ano_semestre FROM '^(\d+)')::INT);
        v_proximo_semestre := (v_ano_atual + 1)::TEXT || 'Is';
    ELSE
         RETURN jsonb_build_object(
            'success', false, 
            'message', 'Formato de semestre desconhecido: ' || COALESCE(v_turma_atual.ano_semestre, 'null')
        );
    END IF;

    -- 4. Achar a turma do mesmo curso/turno mas do semestre seguinte
    SELECT id, cod_turma, turno, cod_turma || ' - ' || turno AS nome_composto
    INTO v_id_proxima_turma, v_nome_proxima_turma, v_turno_proxima_turma, v_nome_composto_proxima_turma
    FROM public.turmas
    WHERE id_curso = v_turma_atual.id_curso
      AND turno = v_turma_atual.turno
      AND ano_semestre = v_proximo_semestre
    LIMIT 1;

    IF v_id_proxima_turma IS NULL THEN
        RETURN jsonb_build_object(
            'success', false, 
            'message', 'Nenhuma turma encontrada para o semestre seguinte: ' || v_proximo_semestre,
            'proximo_semestre', v_proximo_semestre
        );
    END IF;

    -- 5. Verificar se JÁ existe matrícula na turma de destino
    SELECT EXISTS (
        SELECT 1 
        FROM public.matriculas 
        WHERE id_aluno = p_id_user_expandido 
          AND id_turma = v_id_proxima_turma
    ) INTO v_existe_matricula_destino;

    IF v_existe_matricula_destino THEN
        -- Retorna mensagem avisando que já existe
        RETURN jsonb_build_object(
            'success', true, 
             -- O usuário pediu: "Já foi realizada uma matrícula para este estudante na turma ..."
            'message', 'Já foi realizada uma matrícula para este estudante na turma ' || COALESCE(v_nome_composto_proxima_turma, 'Sem Nome'),
            'id_matricula', (SELECT id FROM public.matriculas WHERE id_aluno = p_id_user_expandido AND id_turma = v_id_proxima_turma LIMIT 1),
            'proxima_turma_id', v_id_proxima_turma,
            'proximo_semestre', v_proximo_semestre,
            'nome_turma', v_nome_proxima_turma,
            'turno', v_turno_proxima_turma,
            'nome_composto', v_nome_composto_proxima_turma
        );
    ELSE
        -- 6. Criar a matrícula para este aluno na turma SEGUINTE (sem marcar rematricula=true nela)
        INSERT INTO public.matriculas (id_aluno, id_turma, status)
        VALUES (p_id_user_expandido, v_id_proxima_turma, 'Ativa')
        RETURNING id INTO v_id_matricula;

        -- 7. Marcar a matrícula ATUAL (origem) como re-matriculada
        UPDATE public.matriculas 
        SET rematricula = true,
            atualizado_em = now()
        WHERE id_aluno = p_id_user_expandido 
          AND id_turma = p_id_turma_atual;

        RETURN jsonb_build_object(
            'success', true, 
            'message', 'Rematricula realizada com sucesso na turma: ' || COALESCE(v_nome_composto_proxima_turma, 'Sem Nome'),
            'id_matricula', v_id_matricula, 
            'proxima_turma_id', v_id_proxima_turma,
            'proximo_semestre', v_proximo_semestre,
            'nome_turma', v_nome_proxima_turma,
            'turno', v_turno_proxima_turma,
            'nome_composto', v_nome_composto_proxima_turma
        );
    END IF;
END;
$function$;
