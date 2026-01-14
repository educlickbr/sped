import { format, formatInTimeZone } from "date-fns-tz";
import { ptBR } from "date-fns/locale";
import { parseISO } from "date-fns";

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
        let d: Date;
        if (typeof date === "string") {
            // If the string is exactly YYYY-MM-DD (10 chars), force it to noon to prevent timezone shifts
            // e.g. "2026-01-16" -> UTC midnight -> Brazil previous day 21:00.
            // By adding T12:00:00, it becomes UTC noon -> Brazil 09:00 (same day).
            if (date.trim().length === 10) {
                d = new Date(date.trim() + "T12:00:00");
            } else {
                // For timestamps like "2026-01-16 03:00:00+00", replace space with T for better parsing
                // or just let Date handle it if it works.
                // Ensuring replace(" ", "T") helps some browsers parse properly.
                const sanitized = date.trim().replace(" ", "T");
                d = new Date(sanitized); 
            }
        } else {
            d = date;
        }
        
        // If invalid date
        if (isNaN(d.getTime())) return "";

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
