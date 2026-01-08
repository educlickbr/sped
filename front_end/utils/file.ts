export const generateUuidFileName = (originalName: string): string => {
    const extension = originalName.split(".").pop() || "";
    const uuid = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(
        /[xy]/g,
        function (c) {
            const r = Math.random() * 16 | 0;
            const v = c === "x" ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        },
    );
    return `${uuid}.${extension}`;
};

export const fileToBase64 = (file: File): Promise<string> => {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.readAsDataURL(file);
        reader.onload = () => {
            if (typeof reader.result === "string") {
                const base64 = reader.result.split(",")[1];
                if (base64) {
                    resolve(base64);
                } else {
                    reject(new Error("Base64 conversion failed"));
                }
            } else {
                reject(new Error("Failed to convert file to base64"));
            }
        };
        reader.onerror = (error) => reject(error);
    });
};

export const validateFile = (
    file: File,
    allowedTypes?: string[],
): { valid: boolean; error?: string } => {
    // Max size 4MB (To keep base64 payload under 6MB Edge Function limit)
    const MAX_SIZE = 4 * 1024 * 1024;
    if (file.size > MAX_SIZE) {
        return { valid: false, error: "O arquivo deve ter no máximo 4MB." };
    }

    // Allowed types
    const DEFAULT_TYPES = [
        "application/pdf",
        "image/jpeg",
        "image/png",
        "image/jpg",
    ];

    const typesToCheck = allowedTypes || DEFAULT_TYPES;

    if (!typesToCheck.includes(file.type)) {
        // Create a user-friendly message
        const extensions = typesToCheck.map((t) => {
            const parts = t.split("/");
            return parts[1] ? parts[1].toUpperCase() : "";
        }).join(", ");
        return {
            valid: false,
            error: `Tipo de arquivo inválido. Permitido: ${extensions}.`,
        };
    }

    return { valid: true };
};

export const formatFileSize = (bytes: number): string => {
    if (bytes === 0) return "0 Bytes";
    const k = 1024;
    const sizes = ["Bytes", "KB", "MB", "GB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i];
};
