# Guia de Workflow: Supabase CLI & Nuxt

Este documento resume a configuração e o fluxo de trabalho para o Supabase no projeto **Conecte Nuxt**.

## 1. Configuração Inicial

### Nuxt Frontend
O módulo `@nuxtjs/supabase` deve estar registrado no `nuxt.config.ts`.
A configuração de redirecionamento automático está ativa:
- **Login**: `/login` (página para onde usuários não autenticados são enviados).
- **Callback**: `/confirm` (página que processa o retorno de autenticação).
- **Público**: `/` (página inicial liberada para todos).

### Variáveis de Ambiente (`.env`)
Certifique-se de que o arquivo `.env` na pasta `front_end` contenha:
- `SUPABASE_URL`
- `SUPABASE_KEY`

---

## 2. Supabase CLI (Raiz do Projeto)

O CLI está instalado na raiz para gerenciar funções e banco de dados.

### Comandos Essenciais:
- **Sincronizar Banco Remoto**: `npx supabase db pull`
- **Vincular Projeto**: `npx supabase link --project-ref SEU_ID`
- **Login no CLI**: `npx supabase login`

---

## 3. Fluxo de Alterações no Banco (Migrations)

**NUNCA** altere o banco diretamente pelo Dashboard Web para coisas estruturais. Siga este fluxo:

1. **Criar Nova Migração**:
   ```powershell
   npx supabase migration new nome_da_alteracao
   ```
   *Isso cria um arquivo timestamped em `supabase/migrations/`.*

2. **Escrever o SQL**:
   Edite o arquivo gerado com os comandos `CREATE TABLE`, `ALTER TABLE`, etc.

3. **Subir para o Supabase**:
   ```powershell
   npx supabase db push
   ```

4. **Git**:
   Dê `git push` para salvar o código da migração no repositório. O Git salva o histórico, mas o `db push` é o que altera o banco real.

---

## 4. Ferramental Recomendado

### Visualização de Dados
- **Dashboard Web**: Melhor para gerenciar RLS, Auth e Storage.
- **Extensão PostgreSQL (VS Code)**: Ótima para consultas rápidas. Use a **porta 5432** para conexões mais estáveis.
- **Supabase Studio Local**: Disponível em `localhost:54323` após rodar `npx supabase start`.

### Dicas de Produtividade
- Se a extensão do VS Code desconectar, tente usar o comando `PostgreSQL: Connect` ou reinicie a sessão dando *Refresh* no servidor.
- Use o Docker Desktop apenas quando for rodar o Supabase localmente ou fazer `db pull`. Para apenas codar o frontend, ele não precisa estar ligado.
