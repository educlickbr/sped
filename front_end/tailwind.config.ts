import type { Config } from 'tailwindcss'

export default <Partial<Config>>{
    theme: {
        extend: {
            colors: {
                'text': 'var(--color-text)',
                'background': 'var(--color-background)',
                'primary': 'var(--color-primary)',
                'primary-dark': 'var(--color-primary-hover)',
                'secondary': 'var(--color-secondary)',
                'secondary-hover': 'var(--color-secondary-hover)',
                'div-15': 'var(--color-secondary-surface)',
                'div-30': 'var(--color-secondary-surface-hover)',
                'danger': 'var(--color-danger)',
                'success': 'var(--color-success)',
                'warning': 'var(--color-warning)',
            },
            fontFamily: {
                'sans': ['Inter', 'system-ui', 'Avenir', 'Helvetica', 'Arial', 'sans-serif'],
            }
        }
    },
    plugins: [],
    content: [
        `app/components/**/*.{vue,js,ts}`,
        `app/layouts/**/*.vue`,
        `app/pages/**/*.vue`,
        `app/composables/**/*.{js,ts}`,
        `app/plugins/**/*.{js,ts}`,
        `app/utils/**/*.{js,ts}`,
        `app/App.{js,ts,vue}`,
        `app/app.{js,ts,vue}`,
        `app/Error.{js,ts,vue}`,
        `app/error.{js,ts,vue}`,
        `app/app.config.{js,ts}`
    ]
}
