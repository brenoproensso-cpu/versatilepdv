# Regras do projeto (Versatile PDV)

## Segurança — Supabase

- **Toda tabela nova criada no Supabase deve vir com RLS (Row Level Security) já habilitado desde a criação**, nunca como um passo separado/posterior. Tabelas novas nascem sem RLS por padrão e ficam expostas via API pública (chave `anon`) até serem travadas — isso já causou um incidente real (tabela `vendas_backup_custo_20261014`, criada sem RLS, 549 registros de vendas expostos até ser corrigido).
  - Se a tabela é só de uso interno/administrativo (ex.: backups, migrações, auditoria técnica) e não precisa ser acessada pelo app: `ALTER TABLE "public"."<tabela>" ENABLE ROW LEVEL SECURITY;` sem nenhuma policy — bloqueia completamente o acesso via API pública, e o acesso direto (SQL/admin) continua funcionando normalmente.
  - Se a tabela precisa ser lida/gravada pelo app, criar as policies adequadas (mesmo padrão de permissão já usado nas tabelas existentes) **na mesma migration** que cria a tabela.
  - Sempre incluir o `ENABLE ROW LEVEL SECURITY` (e as policies, se houver) no mesmo comando/migration da criação da tabela — nunca como etapa posterior que pode ser esquecida.
