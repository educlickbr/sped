export function useToast() {
  const ensureContainer = () => {
    let container = document.getElementById('nuxt-toast-container') as HTMLDivElement | null
    if (!container) {
      container = document.createElement('div')
      container.id = 'nuxt-toast-container'
      Object.assign(container.style, {
        position: 'fixed',
        top: '20px',
        right: '20px',
        zIndex: '9999',
        display: 'flex',
        flexDirection: 'column',
        gap: '8px',
        alignItems: 'flex-end',
        pointerEvents: 'none'
      } as Partial<CSSStyleDeclaration>)
      document.body.appendChild(container)
    }
    return container
  }

  const showToast = (message: string, opts?: { duration?: number; type?: 'info' | 'error' }) => {
    const duration = opts?.duration ?? 5000
    const type = opts?.type ?? 'info'
    const container = ensureContainer()

    const toast = document.createElement('div')
    toast.textContent = message
    Object.assign(toast.style, {
      pointerEvents: 'auto',
      background: type === 'error' ? '#ef4444' : '#111827',
      color: '#fff',
      padding: '10px 14px',
      borderRadius: '8px',
      boxShadow: '0 6px 18px rgba(0,0,0,0.12)',
      maxWidth: '340px',
      fontSize: '13px',
      opacity: '0',
      transform: 'translateY(-8px)',
      transition: 'all 180ms ease'
    } as Partial<CSSStyleDeclaration>)

    container.appendChild(toast)

    // show
    requestAnimationFrame(() => {
      toast.style.opacity = '1'
      toast.style.transform = 'translateY(0)'
    })

    const hide = () => {
      toast.style.opacity = '0'
      toast.style.transform = 'translateY(-8px)'
      setTimeout(() => {
        if (toast.parentElement) toast.parentElement.removeChild(toast)
      }, 200)
    }

    let timer = window.setTimeout(hide, duration)
    toast.addEventListener('mouseenter', () => clearTimeout(timer))
    toast.addEventListener('mouseleave', () => {
      timer = window.setTimeout(hide, (duration / 2) | 0)
    })

    return { hide }
  }

  return { showToast }
}
