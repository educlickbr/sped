CREATE OR REPLACE FUNCTION public.get_turmas_filtradas(
	p_ano_semestre text,
	p_turno text DEFAULT NULL::text,
	p_area text DEFAULT NULL::text)
    RETURNS jsonb
    LANGUAGE plpgsql
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;

ALTER FUNCTION public.get_turmas_filtradas(p_ano_semestre text, p_turno text DEFAULT NULL::text, p_area text DEFAULT NULL::text)
    OWNER TO postgres;
