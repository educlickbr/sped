-- Trigger: trg_fila_email
-- Description: Trigger to execute par_trg_fila_email when a new email thread is created.
-- Autor: Antigravity
-- Data: 2025-12-10

CREATE OR REPLACE TRIGGER trg_fila_email
    AFTER INSERT
    ON public.email_threads
    FOR EACH ROW
    EXECUTE FUNCTION public.par_trg_fila_email();
