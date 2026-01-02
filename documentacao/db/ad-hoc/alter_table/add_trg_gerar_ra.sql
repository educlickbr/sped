-- Drop trigger if exists (compatibility for Postgres < 14)
DROP TRIGGER IF EXISTS trg_gerar_ra_matricula ON public.matriculas;

-- Create trigger using EXECUTE PROCEDURE (standard for triggers)
CREATE TRIGGER trg_gerar_ra_matricula
    AFTER INSERT
    ON public.matriculas
    FOR EACH ROW
    EXECUTE PROCEDURE public.fn_gerar_ra_matricula();