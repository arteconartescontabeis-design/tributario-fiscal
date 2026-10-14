-- DESFAZER TUDO · banco do departamento (analise-tributaria-pro) — só se a migração do NCM for ABANDONADA
-- Remove o que a migração acrescentou (001, 002, 003). Nenhuma tabela atp_* é tocada.
-- ATENÇÃO: apaga os dados do NCM gravados no banco do departamento. Depois da virada, só com backup na mão.
drop schema if exists migracao_ncm cascade;
drop table if exists public.ncm_varredura_itens, public.ncm_varreduras, public.ncm_buscas, public.ncm_classificados,
                     public.ncm_acessos, public.ncm_auditoria, public.ncm_usuarios, public.ncm_tenants cascade;
drop function if exists public.ncm_admin_vincular_por_email(text, text, text), public.ncm_vincular_usuario(text),
                        public.ncm_eh_admin(), public.ncm_tenant_atual(), public.ncm_touch();
