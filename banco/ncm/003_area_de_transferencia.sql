-- 003 · Área de transferência dos dados do NCM — 14/10/2026
-- Onde rodar: projeto analise-tributaria-pro. Idempotente. APLICADO em 14/10/2026. Rodar depois do 001.
-- O schema migracao_ncm recebe, SEM alteração, os dados da última cópia de backup do projeto ncm-pro
-- (comando "copiar-ncm" do backup-supabase.py, no ARTEDB01 — os dados não passam pelo chat).
-- Depois, 004_copiar_dados.sql leva para public.ncm_* trocando o login do NCM pelo login do departamento.
-- Não fica exposto na API (só o schema public é publicado) e ninguém além do dono do banco acessa.

create schema if not exists migracao_ncm;
revoke all on schema migracao_ncm from public, anon, authenticated;
comment on schema migracao_ncm is 'Temporário: transferência dos dados do NCM Pro (10/2026). Apagar depois da virada.';

create table if not exists migracao_ncm.ncm_tenants         (like public.ncm_tenants);
create table if not exists migracao_ncm.ncm_usuarios        (like public.ncm_usuarios);
create table if not exists migracao_ncm.ncm_classificados   (like public.ncm_classificados);
create table if not exists migracao_ncm.ncm_buscas          (like public.ncm_buscas);
create table if not exists migracao_ncm.ncm_varreduras      (like public.ncm_varreduras);
create table if not exists migracao_ncm.ncm_varredura_itens (like public.ncm_varredura_itens);
create table if not exists migracao_ncm.ncm_auditoria       (like public.ncm_auditoria);
create table if not exists migracao_ncm.ncm_acessos         (like public.ncm_acessos);
