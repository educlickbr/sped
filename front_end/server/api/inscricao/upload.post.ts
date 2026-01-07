import { serverSupabaseClient, serverSupabaseUser } from "#supabase/server";

export default defineEventHandler(async (event) => {
    // 1. Auth Check
    const user = await serverSupabaseUser(event);
    if (!user) {
        throw createError({
            statusCode: 401,
            statusMessage: "Unauthorized",
        });
    }

    // 2. Read Body
    const body = await readBody(event);
    const { fileBase64, fileName, originalName, id_pergunta, id_turma } = body;

    if (!fileBase64 || !fileName || !id_pergunta || !id_turma) {
        throw createError({
            statusCode: 400,
            statusMessage: "Missing required fields",
        });
    }

    // 3. Upload to Bunny.net Direct (Server-Side)
    const STORAGE_ZONE_NAME = process.env.BUNNY_STORAGE_ZONE_NAME;
    const ACCESS_KEY = process.env.BUNNY_ACCESS_KEY;
    const REGION = process.env.BUNNY_REGION || "br";

    if (!STORAGE_ZONE_NAME || !ACCESS_KEY) {
        console.error("Bunny.net keys missing in .env");
        throw createError({
            statusCode: 500,
            statusMessage: "Server misconfiguration: Storage keys missing",
        });
    }

    // Decode Base64 to Buffer
    const binaryData = Buffer.from(fileBase64, "base64");

    // Construct URL (Defaulting to BR region pattern as requested)
    // Pattern: https://{region}.storage.bunnycdn.com/{storageZone}/{path}/{fileName}
    // Note: Main region (DE) usually omits prefix, but we default to BR here.
    const hostname = `${REGION}.storage.bunnycdn.com`;
    const normalizedPath = "usr";

    // Ensure filename is safe (though it's a UUID usually)
    const safeFileName = encodeURIComponent(fileName);

    const bunnyUrl =
        `https://${hostname}/${STORAGE_ZONE_NAME}/${normalizedPath}/${safeFileName}`;

    try {
        const bunnyRes = await fetch(bunnyUrl, {
            method: "PUT",
            headers: {
                "AccessKey": ACCESS_KEY,
                "Content-Type": "application/octet-stream",
            },
            body: binaryData,
        });

        if (!bunnyRes.ok) {
            const errorText = await bunnyRes.text();
            console.error("Bunny Upload Failed:", bunnyRes.status, errorText);
            throw new Error(`Bunny Storage Error: ${errorText}`);
        }
    } catch (err: any) {
        console.error("Server-Side Upload Exception:", err);
        throw createError({
            statusCode: 502,
            statusMessage: `Upload Service Failed: ${err.message}`,
        });
    }

    // 4. Save Metadata to DB
    const client = await serverSupabaseClient(event);
    const userId = user.id || (user as any).sub;

    const { data, error } = await (client as any).rpc(
        "nxt_salvar_respostas_usuario",
        {
            p_id_usuario: userId,
            p_respostas: [{
                id_pergunta: id_pergunta,
                resposta: fileName, // The UUID filename
                nome_arquivo_original: originalName,
            }],
            p_id_turma: id_turma,
            p_user_expandido_id: null, // Explicitly null to match signature
        },
    );

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        });
    }

    return { success: true, fileName };
});
