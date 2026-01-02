CREATE OR REPLACE FUNCTION public.gerar_ra_aluno_deterministico(
	p_id_aluno uuid,
	p_ano character,
	p_semestre smallint,
	p_ra_legado text DEFAULT NULL::text)
    RETURNS ra_alunos
    LANGUAGE plpgsql
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
  v_ra public.ra_alunos;
  v_email text;
  v_codigo_sequencial int;
  v_codigo_lista int;
  v_milhar int;
  v_ra_texto text;
  v_label text;
begin
  -- Se já existe RA para o aluno, retorna direto
  select * into v_ra
  from public.ra_alunos
  where id_aluno = p_id_aluno
  limit 1;

  if found then
    return v_ra;
  end if;

  -- Pega o e-mail
  select email into v_email
  from public.user_expandido
  where id = p_id_aluno;

  if v_email is null then
    raise exception 'Aluno não encontrado para o id %', p_id_aluno;
  end if;

  -- Calcular posição sequencial para este ano/semestre
  select count(*) + 1 into v_codigo_sequencial
  from public.ra_alunos ra
  join public.user_expandido ue on ue.id = ra.id_aluno
  where ra.ano_ingresso = p_ano
    and ra.semestre_ingresso = p_semestre
    and lower(ue.email) < lower(v_email); -- ordenação estável por email

  -- Milhar e código (como na sua lógica)
  if v_codigo_sequencial <= 999 then
    v_milhar := 1;
    v_codigo_lista := v_codigo_sequencial;
  elsif v_codigo_sequencial <= 1998 then
    v_milhar := 2;
    v_codigo_lista := v_codigo_sequencial - 999;
  elsif v_codigo_sequencial <= 2997 then
    v_milhar := 3;
    v_codigo_lista := v_codigo_sequencial - 1998;
  else
    v_milhar := 4;
    v_codigo_lista := v_codigo_sequencial - 2997;
  end if;

  -- Gerar RA formatado
  v_ra_texto := 'RA-' ||
                right(p_ano, 2) ||
                case
                  when p_semestre = 1 and v_milhar = 1 then '1'
                  when p_semestre = 2 and v_milhar = 1 then '2'
                  when p_semestre = 1 and v_milhar = 2 then '3'
                  when p_semestre = 2 and v_milhar = 2 then '4'
                  when p_semestre = 1 and v_milhar = 3 then '5'
                  when p_semestre = 2 and v_milhar = 3 then '6'
                  when p_semestre = 1 and v_milhar = 4 then '7'
                  else '8'
                end ||
                lpad(v_codigo_lista::text, 3, '0');

  -- Label
  v_label := right(p_ano, 2) || case p_semestre when 1 then 'Is' else 'IIs' end;

  -- Inserir
  insert into public.ra_alunos (
    id_aluno,
    ra,
    ra_legado,
    ano_ingresso,
    semestre_ingresso,
    ano_semestre_ingresso,
    codigo_lista_ano_semestre,
    milhar
  )
  values (
    p_id_aluno,
    v_ra_texto,
    p_ra_legado,
    p_ano,
    p_semestre,
    v_label,
    v_codigo_lista,
    v_milhar
  )
  returning * into v_ra;

  return v_ra;
end;
$BODY$;

ALTER FUNCTION public.gerar_ra_aluno_deterministico(p_id_aluno uuid, p_ano character, p_semestre smallint, p_ra_legado text DEFAULT NULL::text)
    OWNER TO postgres;
