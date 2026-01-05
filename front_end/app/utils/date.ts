import { format, formatInTimeZone } from "date-fns-tz";
import { ptBR } from "date-fns/locale";

const TIMEZONE = "America/Sao_Paulo";

/**
 * Formats a given date (string or Date object) to a specific format string
 * converting it to 'America/Sao_Paulo' timezone.
 * Defaults to 'dd/MM/yyyy'.
 */
export const formatDate = (
    date: string | Date | null | undefined,
    formatStr: string = "dd/MM/yyyy",
): string => {
    if (!date) return "";
    try {
        const d = typeof date === "string" ? new Date(date) : date;
        return formatInTimeZone(d, TIMEZONE, formatStr, { locale: ptBR });
    } catch (e) {
        console.error("Error formatting date:", e);
        return "";
    }
};

/**
 * Returns a short date format ex: "12 SET"
 */
export const formatDayMonth = (
    date: string | Date | null | undefined,
): string => {
    if (!date) return "";
    return formatDate(date, "dd MMM").toUpperCase();
};

/**
 * Returns full date time ex: "12/09/2023 14:30"
 */
export const formatDateTime = (
    date: string | Date | null | undefined,
): string => {
    return formatDate(date, "dd/MM/yyyy HH:mm");
};
