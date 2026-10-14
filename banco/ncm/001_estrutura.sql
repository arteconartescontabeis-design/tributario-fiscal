-- 001 · NCM Pro no banco do departamento Tributário e Fiscal (projeto analise-tributaria-pro) — 14/10/2026
-- Onde rodar: projeto analise-tributaria-pro (kmdrqkiyhdmdtufrogke). Idempotente.
-- APLICADO em 14/10/2026 (em partes, pela ferramenta do Supabase; as tabelas ncm_* nasceram vazias).
-- Só ACRESCENTA objetos ncm_*; nenhuma tabela atp_* é tocada.
-- Igual ao projeto antigo do NCM (ncm-pro), com 3 diferenças de propósito:
--   • os vínculos com auth.users em buscas/varreduras/acessos/classificados usam ON DELETE SET NULL
--     (no antigo, apagar um login com histórico no NCM era bloqueado — aqui isso travaria o ATP);
--   • as políticas valem só para quem está logado (authenticated), não para todos;
--   • a política de alteração de usuários também confere o escritório depois da alteração (WITH CHECK).

create table if not exists public.ncm_tenants (
  id        uuid primary key default gen_random_uuid(),
  nome      text not null,
  cnpj      text,
  slug      text not null unique,
  criado_em timestamptz not null default now()
);

create table if not exists public.ncm_usuarios (
  id        uuid primary key references auth.users(id) on delete cascade,
  tenant_id uuid not null references public.ncm_tenants(id) on delete restrict,
  nome      text,
  email     text,
  papel     text not null default 'operador' check (papel in ('admin', 'operador')),
  ativo     boolean not null default true,
  criado_em timestamptz not null default now()
);

create table if not exists public.ncm_classificados (
  id            uuid primary key default gen_random_uuid(),
  tenant_id     uuid not null references public.ncm_tenants(id) on delete cascade,
  desc_norm     text not null,
  ncm           text not null,
  conf          integer not null default 1,
  criado_por    uuid references auth.users(id) on delete set null,
  criado_em     timestamptz not null default now(),
  atualizado_em timestamptz not null default now(),
  unique (tenant_id, desc_norm)
);

create table if not exists public.ncm_buscas (
  id         uuid primary key default gen_random_uuid(),
  tenant_id  uuid not null references public.ncm_tenants(id) on delete cascade,
  usuario_id uuid references auth.users(id) on delete set null,
  termo      text not null,
  ncm        text,
  em         timestamptz not null default now()
);

create table if not exists public.ncm_varreduras (
  id           uuid primary key default gen_random_uuid(),
  tenant_id    uuid not null references public.ncm_tenants(id) on delete cascade,
  usuario_id   uuid references auth.users(id) on delete set null,
  titulo       text,
  total        integer default 0,
  confirmados  integer default 0,
  revisar      integer default 0,
  divergencias integer default 0,
  criado_em    timestamptz not null default now()
);

create table if not exists public.ncm_varredura_itens (
  id           uuid primary key default gen_random_uuid(),
  varredura_id uuid not null references public.ncm_varreduras(id) on delete cascade,
  produto      text not null,
  ncm_atual    text,
  ncm_sugerido text,
  status       text,
  ipi          text,
  pis_cofins   text,
  ibs_cbs      text,
  divergencia  text
);

create table if not exists public.ncm_auditoria (
  id         uuid primary key default gen_random_uuid(),
  tenant_id  uuid,
  usuario_id uuid,
  acao       text,
  entidade   text,
  detalhe    jsonb,
  em         timestamptz not null default now()
);

create table if not exists public.ncm_acessos (
  id         uuid primary key default gen_random_uuid(),
  tenant_id  uuid not null references public.ncm_tenants(id) on delete cascade,
  usuario_id uuid references auth.users(id) on delete set null,
  email      text,
  em         timestamptz not null default now()
);

create index if not exists ix_ncm_acessos_tenant  on public.ncm_acessos (tenant_id, em desc);
create index if not exists ix_ncm_buscas_tenant   on public.ncm_buscas (tenant_id, em desc);
create index if not exists ix_ncm_classif_tenant  on public.ncm_classificados (tenant_id);
create index if not exists ix_ncm_usuarios_tenant on public.ncm_usuarios (tenant_id);
create index if not exists ix_ncm_varr_itens      on public.ncm_varredura_itens (varredura_id);
create index if not exists ix_ncm_varr_tenant     on public.ncm_varreduras (tenant_id, criado_em desc);

-- funções usadas pelas políticas
create or replace function public.ncm_tenant_atual() returns uuid
  language sql stable security definer set search_path = public as $$
  select tenant_id from ncm_usuarios where id = auth.uid() and ativo;
$$;

create or replace function public.ncm_eh_admin() returns boolean
  language sql stable security definer set search_path = public as $$
  select exists(select 1 from ncm_usuarios where id = auth.uid() and ativo and papel = 'admin');
$$;

create or replace function public.ncm_touch() returns trigger
  language plpgsql set search_path = public as $$
begin new.atualizado_em = now(); return new; end;
$$;

create or replace trigger tg_ncm_classif_touch before update on public.ncm_classificados
  for each row execute function public.ncm_touch();

-- RLS
alter table public.ncm_tenants         enable row level security;
alter table public.ncm_usuarios        enable row level security;
alter table public.ncm_classificados   enable row level security;
alter table public.ncm_buscas          enable row level security;
alter table public.ncm_varreduras      enable row level security;
alter table public.ncm_varredura_itens enable row level security;
alter table public.ncm_auditoria       enable row level security;
alter table public.ncm_acessos         enable row level security;

drop policy if exists p_tenants_sel on public.ncm_tenants;
create policy p_tenants_sel on public.ncm_tenants for select to authenticated using (id = ncm_tenant_atual());

drop policy if exists p_usuarios_sel on public.ncm_usuarios;
create policy p_usuarios_sel on public.ncm_usuarios for select to authenticated using (tenant_id = ncm_tenant_atual());
drop policy if exists p_usuarios_upd on public.ncm_usuarios;
create policy p_usuarios_upd on public.ncm_usuarios for update to authenticated
  using (tenant_id = ncm_tenant_atual() and ncm_eh_admin()) with check (tenant_id = ncm_tenant_atual());
drop policy if exists p_ncm_usuarios_delete on public.ncm_usuarios;
create policy p_ncm_usuarios_delete on public.ncm_usuarios for delete to authenticated using (ncm_eh_admin() and id <> auth.uid());

drop policy if exists p_classif_all on public.ncm_classificados;
create policy p_classif_all on public.ncm_classificados for all to authenticated
  using (tenant_id = ncm_tenant_atual()) with check (tenant_id = ncm_tenant_atual());

drop policy if exists p_buscas_all on public.ncm_buscas;
create policy p_buscas_all on public.ncm_buscas for all to authenticated
  using (tenant_id = ncm_tenant_atual()) with check (tenant_id = ncm_tenant_atual());

drop policy if exists p_varr_all on public.ncm_varreduras;
create policy p_varr_all on public.ncm_varreduras for all to authenticated
  using (tenant_id = ncm_tenant_atual()) with check (tenant_id = ncm_tenant_atual());

drop policy if exists p_varr_itens_all on public.ncm_varredura_itens;
create policy p_varr_itens_all on public.ncm_varredura_itens for all to authenticated
  using (exists (select 1 from ncm_varreduras v where v.id = ncm_varredura_itens.varredura_id and v.tenant_id = ncm_tenant_atual()))
  with check (exists (select 1 from ncm_varreduras v where v.id = ncm_varredura_itens.varredura_id and v.tenant_id = ncm_tenant_atual()));

drop policy if exists p_aud_ins on public.ncm_auditoria;
create policy p_aud_ins on public.ncm_auditoria for insert to authenticated with check (auth.uid() is not null);
drop policy if exists p_aud_sel on public.ncm_auditoria;
create policy p_aud_sel on public.ncm_auditoria for select to authenticated using (tenant_id = ncm_tenant_atual());

drop policy if exists p_acessos_ins on public.ncm_acessos;
create policy p_acessos_ins on public.ncm_acessos for insert to authenticated
  with check (tenant_id = ncm_tenant_atual() and auth.uid() is not null);
drop policy if exists p_acessos_sel on public.ncm_acessos;
create policy p_acessos_sel on public.ncm_acessos for select to authenticated using (tenant_id = ncm_tenant_atual());

comment on table public.ncm_varreduras is 'NCM Pro — varreduras de produtos (migrado do projeto ncm-pro em 10/2026).';
