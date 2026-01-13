export default defineNitroPlugin((nitroApp) => {
  nitroApp.hooks.hook('render:html', (html, { event }) => {
    // Definimos o HTML e CSS do loader crítico aqui
    // Nota: Usamos styles inline e IDs únicos para garantir que nada dependa de arquivos externos no início
    const loaderHtml = `
<div id="nitro-initial-loader" style="position: fixed; inset: 0; z-index: 999999; background-color: #0c0c0c; display: flex; flex-direction: column; align-items: center; justify-content: center; transition: opacity 0.2s ease; color: white;">
    <style>
        @keyframes nitro-spin { to { transform: rotate(360deg); } }
        @keyframes nitro-spin-reverse { to { transform: rotate(-360deg); } }
        #nitro-initial-loader .spinner-outer {
            width: 80px; height: 80px; border: 2px solid rgba(221, 17, 104, 0.2); border-top-color: #dd1168; border-radius: 50%;
            animation: nitro-spin 1s linear infinite;
        }
        #nitro-initial-loader .spinner-inner {
            position: absolute; width: 60px; height: 60px; border: 2px solid rgba(221, 17, 104, 0.1); border-bottom-color: rgba(221, 17, 104, 0.6); border-radius: 50%;
            animation: nitro-spin-reverse 1.5s linear infinite;
        }
        #nitro-initial-loader .loader-text {
            margin-top: 20px; font-family: sans-serif; font-weight: 900; letter-spacing: 0.2em; font-size: 1.2rem; text-transform: uppercase;
        }
    </style>
    <div style="position: relative; display: flex; flex-direction: column; align-items: center; justify-content: center;">
        <div class="spinner-outer"></div>
        <div class="spinner-inner"></div>
        <h2 class="loader-text">AGUARDE</h2>
    </div>
</div>
    `
    // Injetamos no início do body (antes do #__nuxt)
    html.bodyPrepend.push(loaderHtml)
  })
})
