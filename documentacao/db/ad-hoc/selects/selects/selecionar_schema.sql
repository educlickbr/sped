SELECT
    jsonb_agg(
        jsonb_build_object(
            'tabela', tc.table_name,
            'coluna', kcu.column_name,
            'tabela_referenciada', ccu.table_name,
            'coluna_referenciada', ccu.column_name
        )
        ORDER BY tc.table_name, kcu.column_name
    )
FROM
    information_schema.table_constraints AS tc
JOIN
    information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN
    information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE
    tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public';