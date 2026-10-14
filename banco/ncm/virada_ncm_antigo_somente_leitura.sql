-- VIRADA · passo (b) · Projeto ANTIGO do NCM (ncm-pro / lpubtyklsftjinpvcvvq) — só leitura
-- Ninguém grava mais no NCM antigo; ler continua (para conferência e volta atrás).
-- Rodar ANTES da cópia final ("backup --so ncm-pro" + "copiar-ncm").
revoke insert, update, delete, truncate on
  public.ncm_tenants, public.ncm_usuarios, public.ncm_classificados, public.ncm_buscas,
  public.ncm_varreduras, public.ncm_varredura_itens, public.ncm_auditoria, public.ncm_acessos
  from anon, authenticated;
