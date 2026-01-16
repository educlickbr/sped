CREATE OR REPLACE FUNCTION public.nxt_get_estudantes_matriculados_stats(
    p_ano_semestre text, 
    p_turno text DEFAULT NULL::text, 
    p_curso text DEFAULT NULL::text, 
    p_busca text DEFAULT NULL::text, 
    p_status text DEFAULT NULL::text, 
    p_area text DEFAULT NULL::text,
    p_id_turma uuid DEFAULT NULL::uuid
)
RETURNS jsonb
LANGUAGE plpgsql
AS $function$
DECLARE
  v_result jsonb;
BEGIN
  WITH dados AS (
    SELECT
      u.id,
      -- Subselects for filters/grouping
      (SELECT r.resposta FROM respostas r WHERE r.user_expandido_id = u.id AND r.id_pergunta = '25edf1cb-ed2f-4ae2-a85d-ef5c6f0af8ea' LIMIT 1) AS genero,
      (SELECT r.resposta FROM respostas r WHERE r.user_expandido_id = u.id AND r.id_pergunta = '9670c817-5db6-4055-8fc9-04cc15d6cd3e' LIMIT 1) AS raca,
      (SELECT r.resposta FROM respostas r WHERE r.user_expandido_id = u.id AND r.id_pergunta = '98d09feb-ec9a-4a30-882d-7de8099c153f' LIMIT 1) AS renda

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
      
      -- Search Filter
      AND (p_busca IS NULL OR (
           public.normalizar_texto(u.nome) ILIKE '%' || public.normalizar_texto(p_busca) || '%'
        OR public.normalizar_texto(u.sobrenome) ILIKE '%' || public.normalizar_texto(p_busca) || '%'
        OR public.normalizar_texto(u.email) ILIKE '%' || public.normalizar_texto(p_busca) || '%'
        OR ra.ra ILIKE '%' || p_busca || '%'
      ))
  ),
  genero_stats AS (
    SELECT COALESCE(genero, 'Não informado') as label, COUNT(*) as count
    FROM dados
    GROUP BY label
  ),
  raca_stats AS (
    SELECT COALESCE(raca, 'Não informado') as label, COUNT(*) as count
    FROM dados
    GROUP BY label
  ),
  renda_stats AS (
    SELECT COALESCE(renda, 'Não informado') as label, COUNT(*) as count
    FROM dados
    GROUP BY label
  ),
  total_count AS (
    SELECT COUNT(*) as total FROM dados
  )
  
  SELECT jsonb_build_object(
      'total', (SELECT total FROM total_count),
      'genero', (SELECT COALESCE(jsonb_object_agg(label, count), '{}'::jsonb) FROM genero_stats),
      'raca', (SELECT COALESCE(jsonb_object_agg(label, count), '{}'::jsonb) FROM raca_stats),
      'renda', (SELECT COALESCE(jsonb_object_agg(label, count), '{}'::jsonb) FROM renda_stats)
  )
  INTO v_result;

  RETURN v_result;
END;
$function$;
