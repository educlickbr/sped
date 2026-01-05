import { defineStore } from 'pinia'

// Role Definitions
export const ROLES = {
    ADMIN: "d3410ac7-5a4a-4f02-8923-610b9fd87c4d",
    PROFESSOR: "3c4c1d8c-1ad8-4abc-9eea-12829ab7d7f1",
    ALUNO: "b7f53d6e-70b5-453b-b564-728aeb4635d5",
    PROFESSOR_EXTRA: "07028505-01d7-4986-800e-9d71cab5dd6c",
}

export const useAppStore = defineStore('app', {
    state: () => ({
        user: null as any,
        profile: null as any,
        company: null as any,
        role: null as any,
        initialized: false,
        isLoading: false,
        isMenuOpen: false,
        isDark: false
    }),
    actions: {
        async initSession() {
            try {
                const data = await $fetch('/api/me') as any
                this.user = data.user
                this.profile = data.profile
                this.company = data.company
                this.role = data.role
                this.initialized = true
            } catch (err) {
                // Silently fail, data retrieval errors handled by state
            }
        },
        async logout() {
            const supabase = useSupabaseClient()
            await supabase.auth.signOut()

            // Clear user data but preserve company context if possible
            this.user = null
            this.profile = null
            this.role = null

            // Re-fetch to get public company data for the login page
            await this.initSession()
        },
        hasRole(allowedRoles: string[]) {
            if (!this.role) return false
            return allowedRoles.includes(this.role.papel_id)
        },
        setLoading(val: boolean) {
            this.isLoading = val
        },
        toggleMenu() {
            this.isMenuOpen = !this.isMenuOpen
        },
        toggleTheme() {
            this.isDark = !this.isDark
            if (import.meta.client) {
                if (this.isDark) document.documentElement.setAttribute('data-theme', 'dark')
                else document.documentElement.removeAttribute('data-theme')
                localStorage.setItem('theme', this.isDark ? 'dark' : 'light')
            }
        },
        initTheme() {
            if (import.meta.client) {
                const savedTheme = localStorage.getItem('theme')
                this.isDark = savedTheme === 'dark' || (!savedTheme && window.matchMedia('(prefers-color-scheme: dark)').matches)
                if (this.isDark) document.documentElement.setAttribute('data-theme', 'dark')
                else document.documentElement.removeAttribute('data-theme')
            }
        }
    }
})
