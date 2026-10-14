-- 000 · Projeto ANTIGO do NCM (ncm-pro / lpubtyklsftjinpvcvvq) — fecha a falha de acesso — 14/10/2026
-- Onde rodar: SOMENTE no projeto ncm-pro (o antigo). Não é para o banco do departamento.
-- APLICADO em 14/10/2026 e conferido (anon e authenticated sem permissão nas duas funções).
--
-- O problema: o cadastro público desse projeto está aberto (com confirmação de e-mail) e
--   • ncm_vincular_usuario(slug, 'admin') deixava QUALQUER login se tornar admin do NCM;
--   • ncm_bootstrap_admin(e-mail, ...) podia ser chamada até SEM login e promovia um login a admin.
-- Um admin do NCM troca a senha dos outros usuários (ncm_admin_redefinir_senha).
-- Conferido em 14/10/2026: o projeto só tem os 3 logins conhecidos — nenhum sinal de uso indevido.
-- O app não chama nenhuma das duas funções (só aparecem no texto de instalação).

revoke execute on function public.ncm_bootstrap_admin(text, text, text) from public, anon, authenticated;
revoke execute on function public.ncm_vincular_usuario(text, text)      from public, anon, authenticated;

-- Volta atrás (só se precisar):
-- grant execute on function public.ncm_bootstrap_admin(text, text, text) to public, anon, authenticated;
-- grant execute on function public.ncm_vincular_usuario(text, text)      to public, anon, authenticated;
