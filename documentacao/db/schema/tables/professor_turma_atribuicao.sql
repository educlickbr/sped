CREATE TABLE IF NOT EXISTS public.professor_turma_atribuicao (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL, -- Referencia user_expandido(id)
    id_turmas uuid NOT NULL, -- Referencia turmas(id)
    status boolean DEFAULT true,
    avaliador boolean DEFAULT false,
    criado_por uuid, -- Referencia user_expandido(id)
    criado_em timestamp with time zone DEFAULT timezone('utc'::text, now()),
    modificado_por uuid, -- Referencia user_expandido(id)
    modificado_em timestamp with time zone,
    auth_id uuid, -- Campo redundante para facilitar RLS (auth.users.id)

    CONSTRAINT professor_turma_atribuicao_pkey PRIMARY KEY (id),
    CONSTRAINT professor_turma_atribuicao_user_id_fkey FOREIGN KEY (user_id)
        REFERENCES public.user_expandido (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT professor_turma_atribuicao_turmas_fkey FOREIGN KEY (id_turmas)
        REFERENCES public.turmas (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT professor_turma_atribuicao_criado_por_fkey FOREIGN KEY (criado_por)
        REFERENCES public.user_expandido (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE SET NULL,
    CONSTRAINT professor_turma_atribuicao_modificado_por_fkey FOREIGN KEY (modificado_por)
        REFERENCES public.user_expandido (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE SET NULL
);

ALTER TABLE public.professor_turma_atribuicao OWNER TO postgres;

-- Habilitar RLS
ALTER TABLE public.professor_turma_atribuicao ENABLE ROW LEVEL SECURITY;

-- Policies

-- Admin
CREATE POLICY "Admin pode tudo em professor_turma_atribuicao"
    ON public.professor_turma_atribuicao
    TO authenticated
    USING ((auth.jwt() ->> 'papeis_user'::text) = 'admin'::text)
    WITH CHECK ((auth.jwt() ->> 'papeis_user'::text) = 'admin'::text);

-- Secretaria
CREATE POLICY "Secretaria pode tudo em professor_turma_atribuicao"
    ON public.professor_turma_atribuicao
    TO authenticated
    USING ((auth.jwt() ->> 'papeis_user'::text) = 'secretaria'::text)
    WITH CHECK ((auth.jwt() ->> 'papeis_user'::text) = 'secretaria'::text);

-- Docente (Professor)
-- Pode visualizar, criar, editar e deletar seus proprios dados
CREATE POLICY "Docente gerencia seus dados em professor_turma_atribuicao"
    ON public.professor_turma_atribuicao
    TO authenticated
    USING (auth_id = auth.uid())
    WITH CHECK (auth_id = auth.uid());
