alter policy "admin pode tudo em cursos"
on "public"."curso"
to authenticated
using (
    ((auth.jwt() ->> 'papeis_user'::text) = 'admin'::text)
)with check (
    ((auth.jwt() ->> 'papeis_user'::text) = 'admin'::text)
);     