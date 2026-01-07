import { defineStore } from "pinia";

// Role Definitions
export const ROLES = {
    ADMIN: "d3410ac7-5a4a-4f02-8923-610b9fd87c4d",
    PROFESSOR: "3c4c1d8c-1ad8-4abc-9eea-12829ab7d7f1",
    ALUNO: "b7f53d6e-70b5-453b-b564-728aeb4635d5",
    PROFESSOR_EXTRA: "07028505-01d7-4986-800e-9d71cab5dd6c",
};

export const useAppStore = defineStore("app", {
    state: () => ({
        user: null as any,
        profile: null as any,
        company: null as any,
        role: null as any,

        // Expanded Profile Data
        user_expandido_id: null as string | null,
        nome: null as string | null,
        sobrenome: null as string | null,
        imagem_user: null as string | null,
        eixo: null as string | null,
        hash_base: null as string | null,

        initialized: false,
        isLoading: false,
        isMenuOpen: false,
        isDark: false,
    }),
    actions: {
        async initSession() {
            // Fetch ALL session data from BFF in a single call
            try {
                const data = await $fetch("/api/me") as any;

                // Map BFF fields to store state
                this.user = data.user;
                this.profile = data.profile;
                this.company = data.company;
                this.role = data.role;
                this.hash_base = data.hash_base;

                // Expanded Profile Fields
                this.user_expandido_id = data.user_expandido_id;
                this.nome = data.nome;
                this.sobrenome = data.sobrenome;
                this.imagem_user = data.imagem_user;
                this.eixo = data.eixo;
            } catch (err) {
                console.warn(
                    "BFF /api/me call failed, continuing with basic session.",
                );
            }

            this.initialized = true;
        },
        clearProfile() {
            this.user = null;
            this.profile = null;
            this.role = null;
            this.user_expandido_id = null;
            this.nome = null;
            this.sobrenome = null;
            this.imagem_user = null;
            this.eixo = null;
            this.hash_base = null;
        },
        async logout() {
            const supabase = useSupabaseClient();
            await supabase.auth.signOut();

            // Clear session data locally
            this.clearProfile();

            // Re-fetch to normalize state
            await this.initSession();
        },
        hasRole(allowedRoles: string[]) {
            if (!this.role) return false;
            return allowedRoles.includes(this.role.papel_id);
        },
        setLoading(val: boolean) {
            this.isLoading = val;
        },
        toggleMenu() {
            this.isMenuOpen = !this.isMenuOpen;
        },
        toggleTheme() {
            this.isDark = !this.isDark;
            if (import.meta.client) {
                if (this.isDark) {
                    document.documentElement.setAttribute("data-theme", "dark");
                } else document.documentElement.removeAttribute("data-theme");
                localStorage.setItem("theme", this.isDark ? "dark" : "light");
            }
        },
        initTheme() {
            if (import.meta.client) {
                const savedTheme = localStorage.getItem("theme");
                this.isDark = savedTheme === "dark" ||
                    (!savedTheme &&
                        window.matchMedia("(prefers-color-scheme: dark)")
                            .matches);
                if (this.isDark) {
                    document.documentElement.setAttribute("data-theme", "dark");
                } else document.documentElement.removeAttribute("data-theme");
            }
        },
    },
});
