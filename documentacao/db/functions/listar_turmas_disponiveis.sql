CREATE OR REPLACE FUNCTION public.listar_turmas_disponiveis(
	p_data timestamp with time zone DEFAULT NULL::timestamp with time zone,
	p_area text DEFAULT NULL::text,
	p_ano_semestre text DEFAULT NULL::text)
    RETURNS TABLE(id_turma uuid, nome_curso text, area_curso text, area_curso_int text, ano text, ano_semestre text, cod_modulo text, cod_turma text, turno text, dias_semana_array text[], dias_semana_str text, qtd_minutos_total integer, qtd_horas_total numeric, qtd_modulos integer, qtd_encontros_modulo integer, qtd_encontros_totais integer, qtd_minutos_encontro integer, qtd_horas_encontro numeric, qtd_minutos_periodo integer, qtd_horas_periodo numeric, dt_ini_inscri text, dt_fim_inscri text, dt_ini_curso text, dt_fim_curso text, link_video boolean) 
    LANGUAGE sql
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
with params as (
  select
    case
      when p_area is null then null
      when lower(trim(p_area)) in ('extensão','extensao','extensão') then 'extensao'
      when lower(trim(p_area)) in ('cursos livres','curso livre','livres','livre') then 'cursos_livres'
      when lower(trim(p_area)) in ('regulares','regular') then 'regulares'
      else lower(replace(trim(p_area), ' ', '_'))
    end as area_norm,
    p_data as d,
    p_ano_semestre as as_key
)
select
  t.id                                           as id_turma,
  c.nome_curso                                   as nome_curso,

  -- nome "bonito" da área
  case c.area
    when 'extensao' then 'Extensão'
    when 'cursos_livres' then 'Cursos Livres'
    when 'regulares' then 'Regulares'
    else initcap(replace(c.area::text, '_', ' '))
  end                                             as area_curso,

  -- valor interno (enum / sem normalizar)
  (c.area)::text                                 as area_curso_int,

  t.ano::text                                    as ano,
  t.ano_semestre                                 as ano_semestre,
  t.cod_modulo                                   as cod_modulo,
  t.cod_turma                                    as cod_turma,
  t.turno                                        as turno,

  coalesce(array_agg(td.dia_da_semana_text order by td.dia_da_semana_num), '{}'::text[]) as dias_semana_array,
  coalesce(string_agg(td.dia_da_semana_text, ' | ' order by td.dia_da_semana_num), '')    as dias_semana_str,

  c.qtd_minutos_total                            as qtd_minutos_total,
  case when c.qtd_minutos_total is not null
       then round(c.qtd_minutos_total::numeric/60, 2)
       else null end                              as qtd_horas_total,

  c.qtd_modulos                                  as qtd_modulos,
  c.qtd_aulas_modulo                             as qtd_encontros_modulo,
  case when c.qtd_modulos is not null and c.qtd_aulas_modulo is not null
       then c.qtd_modulos * c.qtd_aulas_modulo
       else null end                              as qtd_encontros_totais,

  coalesce(c.qtd_minutos_aula, c.qtd_minutos_periodo)        as qtd_minutos_encontro,
  case when coalesce(c.qtd_minutos_aula, c.qtd_minutos_periodo) is not null
       then round(coalesce(c.qtd_minutos_aula, c.qtd_minutos_periodo)::numeric/60, 2)
       else null end                              as qtd_horas_encontro,

  c.qtd_minutos_periodo                          as qtd_minutos_periodo,
  case when c.qtd_minutos_periodo is not null
       then round(c.qtd_minutos_periodo::numeric/60, 2)
       else null end                              as qtd_horas_periodo,

  -- formato ISO (YYYY-MM-DD) compatível com WeWeb
  to_char(t.dt_ini_inscri at time zone 'America/Sao_Paulo', 'YYYY-MM-DD') as dt_ini_inscri,
  to_char(t.dt_fim_inscri at time zone 'America/Sao_Paulo', 'YYYY-MM-DD') as dt_fim_inscri,
  to_char(t.dt_ini_curso  at time zone 'America/Sao_Paulo', 'YYYY-MM-DD') as dt_ini_curso,
  to_char(t.dt_fim_curso  at time zone 'America/Sao_Paulo', 'YYYY-MM-DD') as dt_fim_curso,
  t.link_video                                   as link_video

from public.turmas t
join public.curso  c on c.id = t.id_curso
left join public.turmas_dias td on td.id_turma = t.id
cross join params p
where
  (p.area_norm is null or (c.area)::text = p.area_norm)
  and (p.as_key is null or t.ano_semestre = p.as_key)
  and (
    p.d is null
    or (
      -- UNICA ALTERAÇÃO: Cast para DATE garante que o dia 02/01 seja maior ou igual a 02/01 até o fim do dia
      (t.dt_ini_inscri at time zone 'America/Sao_Paulo')::date <= (p.d at time zone 'America/Sao_Paulo')::date
      and (t.dt_fim_inscri at time zone 'America/Sao_Paulo')::date >= (p.d at time zone 'America/Sao_Paulo')::date
    )
  )
group by
  t.id, c.nome_curso, c.area, t.ano, t.ano_semestre,
  t.cod_modulo, t.cod_turma, t.turno, c.qtd_minutos_total, c.qtd_modulos,
  c.qtd_aulas_modulo, c.qtd_minutos_aula, c.qtd_minutos_periodo,
  t.dt_ini_inscri, t.dt_fim_inscri, t.dt_ini_curso, t.dt_fim_curso,
  t.link_video
order by
  c.nome_curso, t.ano_semestre, t.cod_modulo, t.cod_turma;
$BODY$;

ALTER FUNCTION public.listar_turmas_disponiveis(p_data timestamp with time zone DEFAULT NULL::timestamp with time zone, p_area text DEFAULT NULL::text, p_ano_semestre text DEFAULT NULL::text)
    OWNER TO postgres;
