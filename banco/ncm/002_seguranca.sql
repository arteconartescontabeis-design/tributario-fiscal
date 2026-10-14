-- 002 · NCM Pro no banco do departamento — acesso e funções administrativas — 14/10/2026
-- Onde rodar: projeto analise-tributaria-pro. Idempotente. APLICADO em 14/10/2026. Rodar depois do 001.
--
-- NÃO vêm do projeto antigo (falha de acesso corrigida em 14/10/2026):
--   ncm_bootstrap_admin        (qualquer pessoa, até sem login, promovia um login a admin)
--   ncm_admin_redefinir_senha  (aqui a senha é a do departamento: redefinir só pelo Análise Tributária Pro)
--   ncm_admin_criar_usuario    (substituída por ncm_admin_vincular_por_email)
-- ncm_vincular_usuario passa a dar acesso SÓ como operador, e só a quem já está logado.

create or replace function public.ncm_vincular_usuario(p_slug text) returns public.ncm_usuarios
  language plpgsql security definer set search_path = public as $$
declare v_tenant uuid; v_row ncm_usuarios;
begin
  if auth.uid() is null then raise exception 'Sem usuário autenticado'; end if;
  select id into v_tenant from ncm_tenants where slug = p_slug;
  if v_tenant is null then raise exception 'Escritório % não encontrado', p_slug; end if;
  insert into ncm_usuarios (id, tenant_id, nome, email, papel)
  select a.id, v_tenant, coalesce(a.raw_user_meta_data->>'name', split_part(a.email, '@', 1)), a.email, 'operador'
    from auth.users a where a.id = auth.uid()
  on conflict (id) do nothing;
  select * into v_row from ncm_usuarios where id = auth.uid();
  return v_row;
end; $$;

-- O admin do NCM dá acesso a um login que JÁ EXISTE no departamento (criado no Análise Tributária Pro).
create or replace function public.ncm_admin_vincular_por_email(p_email text, p_nome text default null, p_papel text default 'operador')
  returns public.ncm_usuarios
  language plpgsql security definer set search_path = public as $$
declare v_tenant uuid; v_uid uuid; v_email text; v_row ncm_usuarios;
begin
  if not ncm_eh_admin() then raise exception 'Apenas administradores do NCM podem dar acesso'; end if;
  select tenant_id into v_tenant from ncm_usuarios where id = auth.uid();
  select id, email into v_uid, v_email from auth.users where lower(email) = lower(trim(p_email));
  if v_uid is null then
    raise exception 'Este e-mail ainda não tem login no departamento. Crie o login no Análise Tributária Pro (Usuários) e tente de novo.';
  end if;
  insert into ncm_usuarios (id, tenant_id, nome, email, papel, ativo)
  values (v_uid, v_tenant, coalesce(nullif(trim(p_nome), ''), split_part(v_email, '@', 1)), v_email,
          case when p_papel = 'admin' then 'admin' else 'operador' end, true)
  on conflict (id) do update set tenant_id = excluded.tenant_id, nome = excluded.nome, papel = excluded.papel, ativo = true
  returning * into v_row;
  return v_row;
end; $$;

-- Quem pode executar: só quem está logado; ninguém sem login.
revoke all on function public.ncm_tenant_atual()                          from public, anon;
revoke all on function public.ncm_eh_admin()                              from public, anon;
revoke all on function public.ncm_touch()                                 from public, anon, authenticated;
revoke all on function public.ncm_vincular_usuario(text)                  from public, anon;
revoke all on function public.ncm_admin_vincular_por_email(text, text, text) from public, anon;
grant execute on function public.ncm_tenant_atual()                          to authenticated;
grant execute on function public.ncm_eh_admin()                              to authenticated;
grant execute on function public.ncm_vincular_usuario(text)                  to authenticated;
grant execute on function public.ncm_admin_vincular_por_email(text, text, text) to authenticated;

-- Tabelas: nada para quem não está logado (a RLS já barrava; isto fecha a porta antes).
revoke all on public.ncm_tenants, public.ncm_usuarios, public.ncm_classificados, public.ncm_buscas,
              public.ncm_varreduras, public.ncm_varredura_itens, public.ncm_auditoria, public.ncm_acessos from anon;
