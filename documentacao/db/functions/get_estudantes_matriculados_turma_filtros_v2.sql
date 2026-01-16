CREATE OR REPLACE FUNCTION public.get_estudantes_matriculados_turma_filtros_v2(p_ano_semestre text, p_turno text DEFAULT NULL::text, p_curso text DEFAULT NULL::text, p_busca text DEFAULT NULL::text, p_genero text DEFAULT NULL::text, p_raca text DEFAULT NULL::text, p_renda text DEFAULT NULL::text, p_id_turma uuid DEFAULT NULL::uuid, p_area text DEFAULT NULL::text, p_status text DEFAULT NULL::text, p_page integer DEFAULT 1, p_limit integer DEFAULT 20)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_result jsonb;
BEGIN
  WITH dados AS (
    SELECT
      -- todas as colunas da matrícula
      m.*,
      m.rematricula,

      -- turma (dados agora vindos de CURSO)
      c.nome_curso AS nome_curso,
      c.area::text AS area_curso,
      t.turno,
      t.ano_semestre,
      (c.nome_curso || ' - ' || t.turno) AS nome_curso_turno,

      -- aluno
      u.id AS aluno_id,
      u.nome,
      u.sobrenome,
      u.email,

      -- RA
      ra.ra,
      ra.ra_legado,

      -- respostas extras
      (SELECT r.resposta FROM respostas r
         WHERE r.user_expandido_id = u.id
           AND r.id_pergunta = '32b1a387-a2a9-4f79-af30-d32026af64fe'
         LIMIT 1) AS nome_social,
      (SELECT r.resposta FROM respostas r
         WHERE r.user_expandido_id = u.id
           AND r.id_pergunta = '25edf1cb-ed2f-4ae2-a85d-ef5c6f0af8ea'
         LIMIT 1) AS genero,
      (SELECT r.resposta FROM respostas r
         WHERE r.user_expandido_id = u.id
           AND r.id_pergunta = '9670c817-5db6-4055-8fc9-04cc15d6cd3e'
         LIMIT 1) AS raca,
      (SELECT r.resposta FROM respostas r
         WHERE r.user_expandido_id = u.id
           AND r.id_pergunta = '98d09feb-ec9a-4a30-882d-7de8099c153f'
         LIMIT 1) AS renda,
      (SELECT r.resposta FROM respostas r
         WHERE r.user_expandido_id = u.id
           AND r.id_pergunta = 'c95e476a-c4dc-4520-badd-d7392b0aeab7'
         LIMIT 1) AS foto_resposta

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
      AND (p_genero IS NULL OR EXISTS (
        SELECT 1 FROM respostas r
        WHERE r.user_expandido_id = u.id
          AND r.id_pergunta = '25edf1cb-ed2f-4ae2-a85d-ef5c6f0af8ea'
          AND public.normalizar_texto(r.resposta) ILIKE '%' || public.normalizar_texto(p_genero) || '%'
      ))
      AND (p_raca IS NULL OR EXISTS (
        SELECT 1 FROM respostas r
        WHERE r.user_expandido_id = u.id
          AND r.id_pergunta = '9670c817-5db6-4055-8fc9-04cc15d6cd3e'
          AND public.normalizar_texto(r.resposta) ILIKE '%' || public.normalizar_texto(p_raca) || '%'
      ))
      AND (p_renda IS NULL OR EXISTS (
        SELECT 1 FROM respostas r
        WHERE r.user_expandido_id = u.id
          AND r.id_pergunta = '98d09feb-ec9a-4a30-882d-7de8099c153f'
          AND public.normalizar_texto(r.resposta) ILIKE '%' || public.normalizar_texto(p_renda) || '%'
      ))
      AND (p_busca IS NULL OR (
           public.normalizar_texto(u.nome) ILIKE '%' || public.normalizar_texto(p_busca) || '%'
        OR public.normalizar_texto(u.sobrenome) ILIKE '%' || public.normalizar_texto(p_busca) || '%'
        OR public.normalizar_texto(u.email) ILIKE '%' || public.normalizar_texto(p_busca) || '%'
        OR EXISTS (
             SELECT 1 FROM respostas r
             WHERE r.user_expandido_id = u.id
               AND r.id_pergunta = '32b1a387-a2a9-4f79-af30-d32026af64fe'
               AND public.normalizar_texto(r.resposta) ILIKE '%' || public.normalizar_texto(p_busca) || '%'
           )
        OR ra.ra ILIKE '%' || p_busca || '%'
        OR ra.ra_legado ILIKE '%' || p_busca || '%'
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
$function$
