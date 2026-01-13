CREATE OR REPLACE FUNCTION public.nxt_get_turmas_seletivo(p_area text DEFAULT NULL::text, p_ano_semestre text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_result jsonb;
begin
  with base as (
    select
      t.id as id_turma,
      (c.nome_curso || ' - ' || coalesce(t.turno, '')) as nome_curso_turno,
      case lower((c.area)::text)
        when 'extensao' then 'Extensão'
        when 'cursos_livres' then 'Cursos Livres'
        when 'regulares' then 'Regulares'
        else initcap((c.area)::text)
      end as area,
      t.ano_semestre,
      t.dt_ini_curso
    from public.turmas t
    join public.curso c on c.id = t.id_curso
    where (p_area is null or lower((c.area)::text) = lower(trim(p_area)))
      and (p_ano_semestre is null or t.ano_semestre = p_ano_semestre)
  ),
  andamento as (
    select id_turma, nome_curso_turno, area, ano_semestre
    from base
    where now() < dt_ini_curso
  ),
  encerrados as (
    select id_turma, nome_curso_turno, area, ano_semestre
    from base
    where now() >= dt_ini_curso
  )
  select jsonb_build_object(
    'em_andamento', coalesce(jsonb_agg(to_jsonb(andamento.*)) filter (where andamento.id_turma is not null), '[]'::jsonb),
    'encerrados', coalesce(jsonb_agg(to_jsonb(encerrados.*)) filter (where encerrados.id_turma is not null), '[]'::jsonb)
  )
  into v_result
  from andamento
  full join encerrados on false;

  return coalesce(v_result, '{}'::jsonb);
end $function$
