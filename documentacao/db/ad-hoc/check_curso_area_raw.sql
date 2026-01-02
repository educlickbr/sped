-- Check RAW content of public.curso.area for the problematic course
SELECT 
    c.id, 
    c.area,
    length(c.area::text) as len_area,
    encode(c.area::text::bytea, 'hex') as hex_area -- Reveals hidden chars
FROM public.curso c
JOIN public.turmas t ON t.id_curso = c.id
WHERE t.id = 'a3f86b8e-72ce-4b4a-a266-68c9d06b58b6'; -- ID from previous JSON for "Danças Urbanas e Musicalidade"
