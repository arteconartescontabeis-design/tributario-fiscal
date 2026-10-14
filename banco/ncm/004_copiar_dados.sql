-- 004 · Leva os dados do NCM da área de transferência (migracao_ncm) para public.ncm_* — banco do departamento
-- Quem roda: o comando "copiar-ncm" do backup-supabase.py, no ARTEDB01, logo depois de carregar migracao_ncm
-- com a última cópia de backup do projeto ncm-pro. Roda numa transação só (psql -1): ou vai tudo, ou nada.
-- SÓ ANTES DA VIRADA: substitui o que houver em public.ncm_* (dados de teste da homologação) pela cópia.
-- Troca o login do NCM antigo pelo login do departamento com o MESMO e-mail (conferido em 14/10/2026: os 3 existem).

-- 1) mapa de logins NCM antigo → departamento
create temp table mapa_login on commit drop as
  select u.id as id_ncm, a.id as id_dep
    from migracao_ncm.ncm_usuarios u
    join auth.users a on lower(a.email) = lower(u.email);

do $do$
declare faltam int; orfaos int;
begin
  select count(*) into faltam from migracao_ncm.ncm_usuarios u
   where not exists (select 1 from mapa_login m where m.id_ncm = u.id);
  if faltam > 0 then
    raise exception 'Há % usuário(s) do NCM sem login com o mesmo e-mail no departamento — nada foi copiado', faltam;
  end if;
  select count(*) into orfaos from (
      select usuario_id as id from migracao_ncm.ncm_buscas
      union all select usuario_id from migracao_ncm.ncm_varreduras
      union all select usuario_id from migracao_ncm.ncm_acessos
      union all select criado_por from migracao_ncm.ncm_classificados) x
   where x.id is not null and not exists (select 1 from mapa_login m where m.id_ncm = x.id);
  if orfaos > 0 then
    raise exception 'Há % registro(s) apontando para login fora do NCM — nada foi copiado', orfaos;
  end if;
end $do$;

-- 2) limpa o destino (dados de teste da homologação), na ordem das dependências
delete from public.ncm_varredura_itens;
delete from public.ncm_varreduras;
delete from public.ncm_buscas;
delete from public.ncm_classificados;
delete from public.ncm_acessos;
delete from public.ncm_auditoria;
delete from public.ncm_usuarios;
delete from public.ncm_tenants;

-- 3) copia (ids das linhas preservados; só o login muda)
insert into public.ncm_tenants (id, nome, cnpj, slug, criado_em)
  select id, nome, cnpj, slug, criado_em from migracao_ncm.ncm_tenants;

insert into public.ncm_usuarios (id, tenant_id, nome, email, papel, ativo, criado_em)
  select m.id_dep, u.tenant_id, u.nome, u.email, u.papel, u.ativo, u.criado_em
    from migracao_ncm.ncm_usuarios u join mapa_login m on m.id_ncm = u.id;

insert into public.ncm_classificados (id, tenant_id, desc_norm, ncm, conf, criado_por, criado_em, atualizado_em)
  select c.id, c.tenant_id, c.desc_norm, c.ncm, c.conf, m.id_dep, c.criado_em, c.atualizado_em
    from migracao_ncm.ncm_classificados c left join mapa_login m on m.id_ncm = c.criado_por;

insert into public.ncm_buscas (id, tenant_id, usuario_id, termo, ncm, em)
  select b.id, b.tenant_id, m.id_dep, b.termo, b.ncm, b.em
    from migracao_ncm.ncm_buscas b left join mapa_login m on m.id_ncm = b.usuario_id;

insert into public.ncm_varreduras (id, tenant_id, usuario_id, titulo, total, confirmados, revisar, divergencias, criado_em)
  select v.id, v.tenant_id, m.id_dep, v.titulo, v.total, v.confirmados, v.revisar, v.divergencias, v.criado_em
    from migracao_ncm.ncm_varreduras v left join mapa_login m on m.id_ncm = v.usuario_id;

insert into public.ncm_varredura_itens (id, varredura_id, produto, ncm_atual, ncm_sugerido, status, ipi, pis_cofins, ibs_cbs, divergencia)
  select id, varredura_id, produto, ncm_atual, ncm_sugerido, status, ipi, pis_cofins, ibs_cbs, divergencia
    from migracao_ncm.ncm_varredura_itens;

insert into public.ncm_auditoria (id, tenant_id, usuario_id, acao, entidade, detalhe, em)
  select a.id, a.tenant_id, coalesce(m.id_dep, a.usuario_id), a.acao, a.entidade, a.detalhe, a.em
    from migracao_ncm.ncm_auditoria a left join mapa_login m on m.id_ncm = a.usuario_id;

insert into public.ncm_acessos (id, tenant_id, usuario_id, email, em)
  select a.id, a.tenant_id, m.id_dep, a.email, a.em
    from migracao_ncm.ncm_acessos a left join mapa_login m on m.id_ncm = a.usuario_id;

-- 4) conferência: cada tabela com o mesmo número de linhas da área de transferência (senão desfaz tudo)
do $do$
declare t text; n_ori bigint; n_dst bigint;
begin
  foreach t in array array['ncm_tenants','ncm_usuarios','ncm_classificados','ncm_buscas','ncm_varreduras',
                           'ncm_varredura_itens','ncm_auditoria','ncm_acessos'] loop
    execute format('select count(*) from migracao_ncm.%I', t) into n_ori;
    execute format('select count(*) from public.%I', t) into n_dst;
    if n_ori <> n_dst then
      raise exception 'Conferência falhou em %: % na cópia × % copiadas — nada foi gravado', t, n_ori, n_dst;
    end if;
  end loop;
end $do$;

-- 5) resumo (aparece na tela do ARTEDB01)
select 'public.' || t as tabela, n as linhas from (
  select 'ncm_tenants' t, count(*) n from public.ncm_tenants union all
  select 'ncm_usuarios', count(*) from public.ncm_usuarios union all
  select 'ncm_classificados', count(*) from public.ncm_classificados union all
  select 'ncm_buscas', count(*) from public.ncm_buscas union all
  select 'ncm_varreduras', count(*) from public.ncm_varreduras union all
  select 'ncm_varredura_itens', count(*) from public.ncm_varredura_itens union all
  select 'ncm_auditoria', count(*) from public.ncm_auditoria union all
  select 'ncm_acessos', count(*) from public.ncm_acessos) x order by 1;
