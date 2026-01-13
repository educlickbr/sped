-- Function: nxt_get_perguntas_avaliacao_com_respostas
CREATE OR REPLACE FUNCTION public.nxt_get_perguntas_avaliacao_com_respostas(p_area tipo_area, p_id_turma uuid DEFAULT NULL::uuid, p_id_user_expandido uuid DEFAULT NULL::uuid, p_id_processo uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_result jsonb;
BEGIN
  
  IF p_id_user_expandido IS NOT NULL AND p_id_processo IS NULL THEN
    RAISE EXCEPTION 'p_id_processo não pode ser NULL quando p_id_user_expandido não é NULL';
  END IF;

  WITH perguntas_base AS (
    SELECT 
      p.id AS id_pergunta,
      p.pergunta,
      p.ordem,
      p.tipo,
      p.opcoes,
      p.opcao_default
    FROM public.perguntas_avaliacao_processos p
    WHERE p.area = p_area
      AND (
            p.id_turma IS NULL
            OR p.id_turma = p_id_turma
          )
  ),

  perguntas_ord AS (
    SELECT *
    FROM perguntas_base
    ORDER BY ordem NULLS LAST, pergunta
  ),

  respostas AS (
    SELECT 
      r.id_pergunta_processo,
      r.resposta_texto
    FROM public.respostas_perguntas_avaliacao_processos r
    WHERE p_id_user_expandido IS NOT NULL
      AND r.id_user = p_id_user_expandido
      AND r.id_processo = p_id_processo
  )

  SELECT jsonb_agg(
      jsonb_build_object(
        'id_pergunta',      q.id_pergunta,
        'pergunta',         q.pergunta,
        'tipo',             q.tipo,
        'opcoes',           q.opcoes,
        'opcao_default',    q.opcao_default,
        'ordem',            q.ordem,
        'id_user_expandido', p_id_user_expandido,
        'id_processo',      p_id_processo,

        ----------------------------------------------------------------
        -- 🟦 Resposta retornada (com defaults por tipo)
        ----------------------------------------------------------------
        'resposta',
          CASE
            WHEN p_id_user_expandido IS NULL THEN
                CASE
                  WHEN q.tipo = 'opcao'  THEN q.opcao_default
                  WHEN q.tipo = 'numero' THEN '0'
                  ELSE ''
                END
            ELSE
                CASE
                  WHEN q.tipo = 'opcao'  THEN COALESCE(r.resposta_texto, q.opcao_default)
                  WHEN q.tipo = 'numero' THEN COALESCE(r.resposta_texto, '0')
                  ELSE COALESCE(r.resposta_texto, '')
                END
          END
      )
  )
  INTO v_result
  FROM perguntas_ord q
  LEFT JOIN respostas r
        ON r.id_pergunta_processo = q.id_pergunta;

  RETURN COALESCE(v_result, '[]'::jsonb);

END;
$function$;

-- Function: nxt_upsert_resposta_avaliacao
CREATE OR REPLACE FUNCTION public.nxt_upsert_resposta_avaliacao(p_id_user uuid, p_id_pergunta uuid, p_id_processo uuid, p_resposta_texto text, p_criado_por uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_row public.respostas_perguntas_avaliacao_processos;
  v_tipo_pergunta text;
  v_soma_notas numeric;
BEGIN

  --------------------------------------------------------------------
  -- ⚠ GARANTIA: id_processo não pode ser nulo
  --------------------------------------------------------------------
  IF p_id_processo IS NULL THEN
    RAISE EXCEPTION 'id_processo não pode ser NULL no upsert_resposta_avaliacao_v2';
  END IF;

  --------------------------------------------------------------------
  -- UPSERT REAL com ON CONFLICT
  -- Baseado na chave lógica: (id_user, id_pergunta_processo, id_processo)
  --------------------------------------------------------------------
  INSERT INTO public.respostas_perguntas_avaliacao_processos (
    id_user,
    id_pergunta_processo,
    id_processo,
    resposta_texto,
    criado_por
  )
  VALUES (
    p_id_user,
    p_id_pergunta,
    p_id_processo,
    p_resposta_texto,
    p_criado_por
  )
  ON CONFLICT (id_user, id_pergunta_processo, id_processo)
  DO UPDATE SET
      resposta_texto = EXCLUDED.resposta_texto,
      criado_por     = EXCLUDED.criado_por,
      criado_em      = now()   -- opcional: marcar atualização
  RETURNING * INTO v_row;

  --------------------------------------------------------------------
  -- LÓGICA DE SOMA DE NOTAS
  -- Verifica o tipo da pergunta atual
  --------------------------------------------------------------------
  SELECT tipo INTO v_tipo_pergunta
  FROM public.perguntas_avaliacao_processos
  WHERE id = p_id_pergunta;

  -- Se for do tipo 'numero', calcula a soma total e atualiza o processo
  IF v_tipo_pergunta = 'numero' THEN
    
    -- Calcula a soma de TODAS as respostas do tipo 'numero' para este processo
    SELECT COALESCE(SUM(r.resposta_texto::numeric), 0)
    INTO v_soma_notas
    FROM public.respostas_perguntas_avaliacao_processos r
    JOIN public.perguntas_avaliacao_processos p ON r.id_pergunta_processo = p.id
    WHERE r.id_processo = p_id_processo
      AND p.tipo = 'numero';

    -- Atualiza o processo com a soma * 100
    UPDATE public.processos
    SET nota_total_processo = (v_soma_notas * 100)::int8
    WHERE id = p_id_processo;

  END IF;

  --------------------------------------------------------------------
  -- Retorno em JSON
  --------------------------------------------------------------------
  RETURN jsonb_build_object(
    'id',                   v_row.id,
    'id_user',              v_row.id_user,
    'id_pergunta',          v_row.id_pergunta_processo,
    'id_processo',          v_row.id_processo,
    'resposta',             v_row.resposta_texto,
    'criado_por',           v_row.criado_por,
    'criado_em',            v_row.criado_em,
    'nota_total_processo',  (SELECT nota_total_processo FROM public.processos WHERE id = p_id_processo) -- Opcional: retornar o novo total
  );

END;
$function$;

-- Function: nxt_upsert_status_processo
CREATE OR REPLACE FUNCTION public.nxt_upsert_status_processo(p_id_processo uuid, p_status text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_updated_status text;
BEGIN
    UPDATE public.processos
    SET status_processo = p_status
    WHERE id = p_id_processo
    RETURNING status_processo INTO v_updated_status;

    RETURN jsonb_build_object(
        'id_processo', p_id_processo,
        'status', v_updated_status
    );
END;
$function$;
