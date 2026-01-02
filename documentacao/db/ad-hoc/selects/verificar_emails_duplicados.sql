-- Verifica usuários com email duplicado (case insensitive)
-- Agrupa por email normalizado e mostra os IDs e detalhes de cada ocorrência
SELECT
    lower(email) as email_normalizado,
    count(*) as quantidade,
    jsonb_agg(
        jsonb_build_object(
            'id', id,
            'user_id', user_id,
            'email_original', email,
            'nome', nome,
            'sobrenome', sobrenome
        )
    ) as registros_duplicados
FROM
    public.user_expandido
GROUP BY
    lower(email)
HAVING
    count(*) > 1
ORDER BY
    quantidade DESC;
