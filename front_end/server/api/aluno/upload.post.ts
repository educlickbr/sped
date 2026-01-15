import { getStudentContext } from '../../utils/student-context'

export default defineEventHandler(async (event) => {
    // 1. Auth Check (Student)
    const { client, userExpandidoId } = await getStudentContext(event)

    // 2. Read Body
    const body = await readBody(event)
    const { fileBase64, fileName, originalName, id_pergunta, id_turma } = body

    if (!fileBase64 || !fileName || !id_pergunta || !id_turma) {
        throw createError({
            statusCode: 400,
            statusMessage: "Missing required fields",
        })
    }

    // 3. Upload to Bunny.net Direct (Server-Side)
    const STORAGE_ZONE_NAME = process.env.BUNNY_STORAGE_ZONE_NAME
    const ACCESS_KEY = process.env.BUNNY_ACCESS_KEY
    const REGION = process.env.BUNNY_REGION || "br"

    if (!STORAGE_ZONE_NAME || !ACCESS_KEY) {
        console.error("Bunny.net keys missing in .env")
        throw createError({
            statusCode: 500,
            statusMessage: "Server misconfiguration: Storage keys missing",
        })
    }

    // Decode Base64 to Buffer
    const binaryData = Buffer.from(fileBase64, "base64")
    const hostname = `${REGION}.storage.bunnycdn.com`
    const normalizedPath = "usr"
    const safeFileName = encodeURIComponent(fileName)
    const bunnyUrl = `https://${hostname}/${STORAGE_ZONE_NAME}/${normalizedPath}/${safeFileName}`

    try {
        const bunnyRes = await fetch(bunnyUrl, {
            method: "PUT",
            headers: {
                "AccessKey": ACCESS_KEY,
                "Content-Type": "application/octet-stream",
            },
            body: binaryData,
        })

        if (!bunnyRes.ok) {
            const errorText = await bunnyRes.text()
            console.error("Bunny Upload Failed:", bunnyRes.status, errorText)
            throw new Error(`Bunny Storage Error: ${errorText}`)
        }
    } catch (err: any) {
        console.error("Server-Side Upload Exception:", err)
        throw createError({
            statusCode: 502,
            statusMessage: `Upload Service Failed: ${err.message}`,
        })
    }

    // 4. Save Metadata to DB via RPC (Student context)
    // We override User ID with authenticated user
    const { data, error } = await (client as any).rpc(
        "salvar_respostas_usuario_v2",
        {
            p_id_usuario: null,
            p_user_expandido_id: userExpandidoId, // Forced from valid session
            p_respostas: [{
                id_pergunta: id_pergunta,
                resposta: fileName, // The UUID filename
                nome_arquivo_original: originalName,
            }]
        }
    )

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        })
    }

    return { success: true, fileName }
})
