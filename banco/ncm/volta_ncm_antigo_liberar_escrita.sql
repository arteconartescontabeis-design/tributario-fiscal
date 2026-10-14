-- VOLTA ATRÁS · Projeto ANTIGO do NCM (ncm-pro / lpubtyklsftjinpvcvvq) — libera a gravação de novo
-- Usar só se a virada for desfeita (o Portal volta a apontar para o NCM antigo).
grant insert, update, delete on
  public.ncm_tenants, public.ncm_usuarios, public.ncm_classificados, public.ncm_buscas,
  public.ncm_varreduras, public.ncm_varredura_itens, public.ncm_auditoria, public.ncm_acessos
  to authenticated;
