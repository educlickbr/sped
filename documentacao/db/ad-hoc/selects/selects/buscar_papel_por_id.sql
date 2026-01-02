SELECT id,
       user_id,
       papel_id
FROM public.papeis_user_auth
WHERE user_id = '3a3b3698-b3fa-44bc-85b5-cdcdfe23bdc9'
LIMIT 1000;