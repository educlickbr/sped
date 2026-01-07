-- Fix logic in trg_atualiza_imagem_user to allow overwriting existing images
-- Previous version prevented update if imagem_user was not empty

CREATE OR REPLACE FUNCTION public.trg_atualiza_imagem_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'extensions', 'public'
AS $function$
begin
  -- 1️⃣ Só age se for a pergunta certa
  if new.id_pergunta = 'c95e476a-c4dc-4520-badd-d7392b0aeab7'::uuid then
    
    -- 2️⃣ Atualiza sempre (condição de vazio removida)
    update public.user_expandido
    set imagem_user = new.resposta
    where 
      id = new.user_expandido_id;
  end if;

  return new;
end;
$function$
