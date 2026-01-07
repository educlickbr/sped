async function renameFileWithGuid(originalFileName) {
    // 🔹 Função para gerar um GUID
    function generateGuid() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            let r = Math.random() * 16 | 0, v = c === 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        });
    }

    // 🔹 Separar a extensão do nome original
    let parts = originalFileName.split('.');
    let extension = parts.length > 1 ? '.' + parts.pop() : ''; // Mantém a extensão

    // 🔹 Gerar novo nome com GUID
    let newFileName = generateGuid() + extension;

    return newFileName; // Retorna o novo nome
}

// 📌 Exemplo de uso no WeWeb:
const originalFileName = context.parameters['nome_arquivo']

return await renameFileWithGuid(originalFileName);