-- Enable RLS on email_threads and email_queue
ALTER TABLE public.email_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_queue ENABLE ROW LEVEL SECURITY;

-- Policy for email_threads (Admin and Secretaria have full access)
DROP POLICY IF EXISTS "Admin e Secretaria completa nas threads" ON public.email_threads;

CREATE POLICY "Admin e Secretaria completa nas threads"
    ON public.email_threads
    FOR ALL
    TO authenticated
    USING (
        (auth.jwt() ->> 'papeis_user'::text) = ANY (ARRAY['admin'::text, 'secretaria'::text])
    )
    WITH CHECK (
        (auth.jwt() ->> 'papeis_user'::text) = ANY (ARRAY['admin'::text, 'secretaria'::text])
    );

-- Policy for email_queue (Admin and Secretaria have full access)
DROP POLICY IF EXISTS "Admin e Secretaria completa na queue" ON public.email_queue;

CREATE POLICY "Admin e Secretaria completa na queue"
    ON public.email_queue
    FOR ALL
    TO authenticated
    USING (
        (auth.jwt() ->> 'papeis_user'::text) = ANY (ARRAY['admin'::text, 'secretaria'::text])
    )
    WITH CHECK (
        (auth.jwt() ->> 'papeis_user'::text) = ANY (ARRAY['admin'::text, 'secretaria'::text])
    );
