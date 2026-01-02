# Configuração do Supabase (Login & Pull)

Este guia explica como autenticar a CLI do Supabase, vincular seu projeto local ao projeto na nuvem e baixar o banco de dados (Pull).

## 1. Login na CLI

Se é a primeira vez que você usa a CLI do Supabase nesta máquina, você precisa fazer login.

Abra o terminal na raiz do projeto (`d:\NUXT\sped_nuxt`) e rode:

```powershell
supabase login
```

*   Isso abrirá seu navegador.
*   Clique em "Confirm" para gerar o token.
*   Volte ao terminal, ele deve confirmar o login.

## 2. Vincular Projeto (Link)

Agora precisamos dizer ao Supabase local qual é o projeto "real" na nuvem (Production) que ele deve espelhar.

Você vai precisar do **Project Ref** (Reference ID).
1.  Vá ao dashboard do Supabase: [https://supabase.com/dashboard/projects](https://supabase.com/dashboard/projects)
2.  Entre no seu projeto.
3.  Olhe a URL: `https://supabase.com/dashboard/project/abcde12345...`
4.  O código final (ex: `abcde12345...`) é o seu **Project Ref**.
    *   Alternativa: Vá em Project Settings > General > Reference ID.

No terminal, execute:

```powershell
supabase link --project-ref <seu-project-ref>
```

*   Ele vai pedir a senha do banco de dados (Database Password) do projeto na nuvem.
*   **Dica:** Se você esqueceu, pode redefinir em Project Settings > Database > Reset Database Password.
* se ainda não fez o git hub faça 
* supabase migration repair --status applied codigo da migration cvriada automaticamenteY

## 3. Primeiro Pull (Baixar o Banco)

Com o projeto vinculado, vamos puxar o esquema do banco de dados da nuvem para o seu ambiente local.

```powershell
supabase db pull
```

*   Isso vai ler o banco de produção e criar (ou atualizar) o arquivo de migração inicial dentro da pasta `supabase/migrations`.
*   Agora seu ambiente local conhece todas as tabelas, funções e tipos do seu banco.

---

## Resumo dos Comandos

```powershell
# 1. Autenticar
supabase login

# 2. Vincular ao projeto remoto
supabase link --project-ref xuq... (seu id)

# 3. Baixar estrutura do banco
supabase db pull
```

**Próximo Passo:**
Após o pull, se você quiser rodar o banco localmente (via Docker), você usaria `supabase start`, mas isso é opcional se você for conectar direto no banco da nuvem pelo `.env`.
