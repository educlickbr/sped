-- 1) nxt_get_turmas_filtradas
CREATE OR REPLACE FUNCTION public.nxt_get_turmas_filtradas(
    p_ano_semestre text, 
    p_turno text DEFAULT NULL::text, 
    p_area text DEFAULT NULL::text
)
RETURNS jsonb
LANGUAGE plpgsql
AS $function$
DECLARE
    v_result jsonb;
BEGIN
  WITH dados AS (
      SELECT
        t.id,
        c.nome_curso,
        (c.area)::text AS area_curso,
        t.turno,
        t.ano_semestre,
        c.cod_curso,
        t.cod_turma,
        t.cod_modulo,
        t.dt_ini_curso,
        t.dt_fim_curso,
        (c.nome_curso || ' - ' || coalesce(t.turno, '')) AS nome_curso_turno
      FROM public.turmas t
      JOIN public.curso c ON c.id = t.id_curso
      WHERE 
        t.ano_semestre = p_ano_semestre

        -- 🔥 turno flexível (opcional)
        AND (
              p_turno IS NULL
              OR normalizar_texto(t.turno) = normalizar_texto(p_turno)
        )

        -- 🔥 área flexível (opcional)
        AND (
              p_area IS NULL
              OR normalizar_texto(c.area::text) = normalizar_texto(p_area)
        )

        AND c.status = TRUE
      ORDER BY c.nome_curso, t.cod_turma
  )
  SELECT jsonb_build_object(
      'total', COUNT(*),
      'turmas', COALESCE(jsonb_agg(to_jsonb(dados)), '[]'::jsonb)
  )
  INTO v_result
  FROM dados;

  RETURN v_result;
END;
$function$;

-- 2) nxt_get_estudantes_matriculados_turma_filtros
CREATE OR REPLACE FUNCTION public.nxt_get_estudantes_matriculados_turma_filtros(
    p_ano_semestre text, 
    p_turno text DEFAULT NULL::text, 
    p_curso text DEFAULT NULL::text, 
    p_busca text DEFAULT NULL::text, 
    p_genero text DEFAULT NULL::text, 
    p_raca text DEFAULT NULL::text, 
    p_renda text DEFAULT NULL::text, 
    p_id_turma uuid DEFAULT NULL::uuid, 
    p_area text DEFAULT NULL::text, 
    p_status text DEFAULT NULL::text, 
    p_page integer DEFAULT 1, 
    p_limit integer DEFAULT 20
)
RETURNS jsonb
LANGUAGE plpgsql
AS $function$
DECLARE
  v_result jsonb;
BEGIN
  WITH dados AS (
    SELECT
      m.*,
      m.rematricula,
      c.nome_curso AS nome_curso,
      c.area::text AS area_curso,
      t.turno,
      t.ano_semestre,
      (c.nome_curso || ' - ' || t.turno) AS nome_curso_turno,
      u.id AS aluno_id,
      u.nome,
      u.sobrenome,
      u.email,
      ra.ra,
      ra.ra_legado,
      -- Subselects otimizados (ou mantidos conforme original se performance for ok)
      (SELECT r.resposta FROM respostas r WHERE r.user_expandido_id = u.id AND r.id_pergunta = '32b1a387-a2a9-4f79-af30-d32026af64fe' LIMIT 1) AS nome_social,
      (SELECT r.resposta FROM respostas r WHERE r.user_expandido_id = u.id AND r.id_pergunta = '25edf1cb-ed2f-4ae2-a85d-ef5c6f0af8ea' LIMIT 1) AS genero,
      (SELECT r.resposta FROM respostas r WHERE r.user_expandido_id = u.id AND r.id_pergunta = '9670c817-5db6-4055-8fc9-04cc15d6cd3e' LIMIT 1) AS raca,
      (SELECT r.resposta FROM respostas r WHERE r.user_expandido_id = u.id AND r.id_pergunta = '98d09feb-ec9a-4a30-882d-7de8099c153f' LIMIT 1) AS renda,
      (SELECT r.resposta FROM respostas r WHERE r.user_expandido_id = u.id AND r.id_pergunta = 'c95e476a-c4dc-4520-badd-d7392b0aeab7' LIMIT 1) AS foto_resposta

    FROM matriculas m
      JOIN turmas t ON t.id = m.id_turma
      JOIN curso c ON c.id = t.id_curso
      JOIN user_expandido u ON u.id = m.id_aluno
      LEFT JOIN ra_alunos ra ON ra.id_aluno = u.id

    WHERE t.ano_semestre = p_ano_semestre
      AND (p_turno IS NULL OR t.turno = p_turno)
      AND (p_area IS NULL OR public.normalizar_texto(c.area::text) = public.normalizar_texto(p_area))
      AND (p_status IS NULL 
           OR (p_status ILIKE 'ativa' AND m.status::text = 'Ativo') 
           OR m.status::text ILIKE p_status)
      AND (p_curso IS NULL OR public.normalizar_texto(c.nome_curso) ILIKE '%' || public.normalizar_texto(p_curso) || '%')
      AND (p_id_turma IS NULL OR t.id = p_id_turma)
      
      -- Filtros extras (genero, raca, renda, busca) mantidos do original
      AND (p_genero IS NULL OR EXISTS (SELECT 1 FROM respostas r WHERE r.user_expandido_id = u.id AND r.id_pergunta = '25edf1cb-ed2f-4ae2-a85d-ef5c6f0af8ea' AND public.normalizar_texto(r.resposta) ILIKE '%' || public.normalizar_texto(p_genero) || '%'))
      AND (p_raca IS NULL OR EXISTS (SELECT 1 FROM respostas r WHERE r.user_expandido_id = u.id AND r.id_pergunta = '9670c817-5db6-4055-8fc9-04cc15d6cd3e' AND public.normalizar_texto(r.resposta) ILIKE '%' || public.normalizar_texto(p_raca) || '%'))
      AND (p_renda IS NULL OR EXISTS (SELECT 1 FROM respostas r WHERE r.user_expandido_id = u.id AND r.id_pergunta = '98d09feb-ec9a-4a30-882d-7de8099c153f' AND public.normalizar_texto(r.resposta) ILIKE '%' || public.normalizar_texto(p_renda) || '%'))
      AND (p_busca IS NULL OR (
           public.normalizar_texto(u.nome) ILIKE '%' || public.normalizar_texto(p_busca) || '%'
        OR public.normalizar_texto(u.sobrenome) ILIKE '%' || public.normalizar_texto(p_busca) || '%'
        OR public.normalizar_texto(u.email) ILIKE '%' || public.normalizar_texto(p_busca) || '%'
        OR ra.ra ILIKE '%' || p_busca || '%'
      ))
  ),
  total AS (
    SELECT count(*) AS total FROM dados
  ),
  paginado AS (
    SELECT * FROM dados
    ORDER BY nome, sobrenome
    LIMIT p_limit OFFSET (p_page - 1) * p_limit
  )
  SELECT jsonb_build_object(
    'total', (SELECT total FROM total),
    'page', p_page,
    'limit', p_limit,
    'pages', ceil((SELECT total FROM total)::numeric / p_limit),
    'alunos', coalesce(jsonb_agg(to_jsonb(paginado)), '[]'::jsonb)
  )
  INTO v_result
  FROM paginado;

  RETURN v_result;
END;
$function$;

-- 3) nxt_get_faltas_aluno_turma
CREATE OR REPLACE FUNCTION public.nxt_get_faltas_aluno_turma(p_id_aluno uuid, p_id_turma uuid)
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

    FOR v_row IN
        SELECT 
            d.*,
            ROW_NUMBER() OVER (ORDER BY d.data ASC) AS encontro_real
        FROM diario d
        WHERE d.id_aluno = p_id_aluno
          AND d.id_turma = p_id_turma
        ORDER BY d.data ASC
    LOOP
        IF v_padrao_encontros THEN
            v_duracao_encontro := v_qtd_periodos * v_qtd_minutos_periodo;
        ELSE
            SELECT ce.duracao_minutos
            INTO v_duracao_encontro
            FROM curso_encontros ce
            WHERE ce.id_curso = v_id_curso
              AND ce.numero_encontro = v_row.encontro_real;

            IF v_duracao_encontro IS NULL THEN
                v_duracao_encontro := v_qtd_periodos * v_qtd_minutos_periodo;
                v_inconsistencias := array_append(
                    v_inconsistencias,
                    format('aula extra na data %s sem correspondência em curso_encontros', v_row.data::date)
                );
            END IF;
        END IF;

        v_minutos_faltados_neste_dia := 0;
        v_minutos_por_periodo := v_duracao_encontro::numeric / v_qtd_periodos;

        IF v_row.p1 = 'falta' THEN v_minutos_faltados_neste_dia := v_minutos_faltados_neste_dia + v_minutos_por_periodo; END IF;
        IF v_qtd_periodos >= 2 AND v_row.p2 = 'falta' THEN v_minutos_faltados_neste_dia := v_minutos_faltados_neste_dia + v_minutos_por_periodo; END IF;
        IF v_qtd_periodos >= 3 AND v_row.p3 = 'falta' THEN v_minutos_faltados_neste_dia := v_minutos_faltados_neste_dia + v_minutos_por_periodo; END IF;
        IF v_qtd_periodos >= 4 AND v_row.p4 = 'falta' THEN v_minutos_faltados_neste_dia := v_minutos_faltados_neste_dia + v_minutos_por_periodo; END IF;

        v_minutos_faltados := v_minutos_faltados + v_minutos_faltados_neste_dia;

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

    IF v_minutos_modulo <= 0 THEN
        RETURN jsonb_build_object('erro', 'Módulo sem carga horária definida');
    END IF;

    DECLARE
        v_percentual_faltas numeric;
        v_percentual_presenca numeric;
    BEGIN
        v_percentual_faltas := v_minutos_faltados / v_minutos_modulo;
        v_percentual_presenca := 1 - v_percentual_faltas;
        v_percentual_faltas := LEAST(v_percentual_faltas, 1);
        v_percentual_presenca := GREATEST(v_percentual_presenca, 0);
        v_percentual_faltas := ROUND(v_percentual_faltas * 100, 2);
        v_percentual_presenca := ROUND(v_percentual_presenca * 100, 2);

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
$function$;
