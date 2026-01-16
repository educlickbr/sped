CREATE OR REPLACE FUNCTION public.get_faltas_aluno_turma(p_id_aluno uuid, p_id_turma uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_result jsonb;
    v_inconsistencias text[] := '{}';
    v_minutos_faltados numeric := 0;
    v_minutos_modulo numeric := 0;
    v_padrao_encontros boolean;
    v_qtd_periodos int;
    v_qtd_minutos_periodo int;
    v_qtd_aulas_modulo int;
    v_id_curso uuid;

    v_row record;
    v_duracao_encontro int;
    v_minutos_por_periodo numeric;
    v_minutos_faltados_neste_dia numeric;

    v_registros jsonb := '[]'::jsonb;
BEGIN
    --------------------------------------------------------------------
    -- 1) Carrega dados do curso + turma
    --------------------------------------------------------------------
    SELECT 
        t.id_curso,
        c.padrao_encontros,
        c.qtd_periodos,
        c.qtd_minutos_periodo,
        c.qtd_minutos_modulo,
        c.qtd_aulas_modulo
    INTO 
        v_id_curso,
        v_padrao_encontros,
        v_qtd_periodos,
        v_qtd_minutos_periodo,
        v_minutos_modulo,
        v_qtd_aulas_modulo
    FROM turmas t
    JOIN curso c ON c.id = t.id_curso
    WHERE t.id = p_id_turma;

    IF v_id_curso IS NULL THEN
        RETURN jsonb_build_object('erro', 'Turma não encontrada');
    END IF;

    --------------------------------------------------------------------
    -- 2) Processar diário ordenado unicamente pela DATA
    --------------------------------------------------------------------
    FOR v_row IN
        SELECT 
            d.*,
            ROW_NUMBER() OVER (ORDER BY d.data ASC) AS encontro_real
        FROM diario d
        WHERE d.id_aluno = p_id_aluno
          AND d.id_turma = p_id_turma
        ORDER BY d.data ASC
    LOOP
        ----------------------------------------------------------------
        -- 3) Determinar a duração do encontro
        ----------------------------------------------------------------
        IF v_padrao_encontros THEN
            -- duração constante
            v_duracao_encontro := v_qtd_periodos * v_qtd_minutos_periodo;

        ELSE
            -- curso irregular → tentar achar a duração específica no curso_encontros
            SELECT ce.duracao_minutos
            INTO v_duracao_encontro
            FROM curso_encontros ce
            WHERE ce.id_curso = v_id_curso
              AND ce.numero_encontro = v_row.encontro_real;

            IF v_duracao_encontro IS NULL THEN
                -- Aula extra → usar fallback
                v_duracao_encontro := v_qtd_periodos * v_qtd_minutos_periodo;

                v_inconsistencias := array_append(
                    v_inconsistencias,
                    format('aula extra na data %s sem correspondência em curso_encontros', v_row.data::date)
                );
            END IF;

        END IF;

        ----------------------------------------------------------------
        -- 4) Calcular faltas do dia (dinâmico para p1–p4)
        ----------------------------------------------------------------
        v_minutos_faltados_neste_dia := 0;
        v_minutos_por_periodo := v_duracao_encontro::numeric / v_qtd_periodos;

        -- P1
        IF v_row.p1 = 'falta' THEN
            v_minutos_faltados_neste_dia := v_minutos_faltados_neste_dia + v_minutos_por_periodo;
        END IF;

        -- P2
        IF v_qtd_periodos >= 2 AND v_row.p2 = 'falta' THEN
            v_minutos_faltados_neste_dia := v_minutos_faltados_neste_dia + v_minutos_por_periodo;
        END IF;

        -- P3
        IF v_qtd_periodos >= 3 AND v_row.p3 = 'falta' THEN
            v_minutos_faltados_neste_dia := v_minutos_faltados_neste_dia + v_minutos_por_periodo;
        END IF;

        -- P4
        IF v_qtd_periodos >= 4 AND v_row.p4 = 'falta' THEN
            v_minutos_faltados_neste_dia := v_minutos_faltados_neste_dia + v_minutos_por_periodo;
        END IF;

        v_minutos_faltados := v_minutos_faltados + v_minutos_faltados_neste_dia;

        ----------------------------------------------------------------
        -- 5) inserir no array de registros
        ----------------------------------------------------------------
        v_registros := v_registros || jsonb_build_object(
            'data', v_row.data::date,
            'p1', v_row.p1,
            'p2', v_row.p2,
            'p3', v_row.p3,
            'p4', v_row.p4,
            'duracao_encontro', v_duracao_encontro,
            'minutos_faltados_neste_dia', v_minutos_faltados_neste_dia
        );
    END LOOP;

    --------------------------------------------------------------------
    -- 6) Cálculo final com cortes (máx 100%)
    --------------------------------------------------------------------
    IF v_minutos_modulo <= 0 THEN
        RETURN jsonb_build_object('erro', 'Módulo sem carga horária definida');
    END IF;

    -- percentual real
    -- ex: 0.24 → depois convertendo para % arredondado (24.00)
    DECLARE
        v_percentual_faltas numeric;
        v_percentual_presenca numeric;
    BEGIN
        v_percentual_faltas := v_minutos_faltados / v_minutos_modulo;
        v_percentual_presenca := 1 - v_percentual_faltas;

        -- cortes
        v_percentual_faltas := LEAST(v_percentual_faltas, 1);
        v_percentual_presenca := GREATEST(v_percentual_presenca, 0);

        -- conversão para porcentagem
        v_percentual_faltas := ROUND(v_percentual_faltas * 100, 2);
        v_percentual_presenca := ROUND(v_percentual_presenca * 100, 2);

        ----------------------------------------------------------------
        -- 7) Monta JSON final
        ----------------------------------------------------------------
        v_result := jsonb_build_object(
            'id_aluno', p_id_aluno,
            'id_turma', p_id_turma,
            'qtd_periodos', v_qtd_periodos,
            'padrao_encontros', v_padrao_encontros,
            'minutos_faltados', v_minutos_faltados,
            'horas_faltadas', ROUND(v_minutos_faltados / 60.0, 2),
            'horas_totais_modulo', (v_minutos_modulo / 60.0),
            'percentual_faltas', v_percentual_faltas,
            'percentual_presenca', v_percentual_presenca,
            'registros', v_registros,
            'inconsistencias', v_inconsistencias
        );
    END;

    RETURN v_result;
END;
$function$
