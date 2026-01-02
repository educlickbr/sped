CREATE OR REPLACE TRIGGER trg_gerar_ra_matricula
    AFTER INSERT
    ON public.matriculas
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_gerar_ra_matricula();