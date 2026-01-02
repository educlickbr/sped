-- Policy for users to view/manage their own reservations
-- Only specific roles are allowed, and only for their own data (auth_user_id match)

-- Substitua 'papel_aqui', 'outro_papel' pelos nomes reais dos papeis (ex: 'aluno', 'professor')
CREATE POLICY "Papeis especificos veem suas proprias reservas"
ON "public"."produto_reservas"
TO authenticated
USING (
  (auth.uid() = auth_user_id)
  AND
  ((auth.jwt() ->> 'papeis_user'::text) = ANY (ARRAY['docente'::text, 'outro_papel'::text]))
)
WITH CHECK (
  (auth.uid() = auth_user_id)
  AND
  ((auth.jwt() ->> 'papeis_user'::text) = ANY (ARRAY['docente'::text, 'outro_papel'::text]))
);
