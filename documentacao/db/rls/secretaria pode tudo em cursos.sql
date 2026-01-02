alter policy "secretaria pode tudo em cursos"
on "public"."curso"
to authenticated
using (
    ((auth.jwt() ->> 'papeis_user'::text) = 'secretaria'::text)
)with check (
    ((auth.jwt() ->> 'papeis_user'::text) = 'secretaria'::text)
);  