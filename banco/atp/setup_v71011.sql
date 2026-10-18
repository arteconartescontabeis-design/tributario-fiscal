-- ═══════════════════════════════════════════════════════════════════════════════
--  Análise Tributária Pro v7.101.1 — Histórico robusto (B10)
--  Rodar no SQL Editor do Supabase (idempotente: pode rodar mais de uma vez).
--
--  ⚠️ NADA é aplicado pelo aplicativo: este arquivo existe para a SUA revisão e
--  execução manual. Sem ele o Histórico continua como hoje (frágil): autor vindo
--  do navegador e qualquer usuário autenticado podendo apagar linhas.
--
--  TRÊS CORREÇÕES (pendência 3 do relatório de 18/10/2026):
--   1) AUTOR PELO SERVIDOR — um trigger grava gravado_por a partir do e-mail do
--      token (auth.jwt), ignorando o que o navegador mandar: ninguém assina pelo
--      colega, nem por engano nem de propósito.
--   2) DELETE SÓ DE ADMINISTRADOR — a política de DELETE exige papel 'admin'
--      (atp_sou_admin); usuário comum não apaga histórico.
--   3) RETENÇÃO DE 24 VERSÕES — a poda (se houver) passa a preservar as 24 mais
--      recentes por empresa/ano (o app mostra 12); a poda roda como SECURITY
--      DEFINER para não depender da política de DELETE.
--
--  ANTES DE RODAR, confira se o setup antigo deixou algum trigger de poda na
--  tabela (o setup_v712.sql original não está neste repositório):
--      select tgname from pg_trigger
--       where tgrelid = 'public.atp_analises_hist'::regclass and not tgisinternal;
--  Se aparecer um trigger de poda com outro nome, remova-o (drop trigger ... on
--  public.atp_analises_hist) — a poda desta versão o substitui.
-- ═══════════════════════════════════════════════════════════════════════════════
begin;

-- 1) Autor gravado pelo servidor ------------------------------------------------
create or replace function public.atp_hist_autor()
returns trigger language plpgsql security definer set search_path = public as $fn$
begin
  -- o e-mail vem do token de quem está logado; o que o navegador mandar é descartado
  new.gravado_por := coalesce(nullif(auth.jwt() ->> 'email', ''), new.gravado_por);
  new.gravado_em  := now();
  return new;
end $fn$;

drop trigger if exists atp_hist_autor_tg on public.atp_analises_hist;
create trigger atp_hist_autor_tg
  before insert on public.atp_analises_hist
  for each row execute function public.atp_hist_autor();

comment on function public.atp_hist_autor is 'v7.101.1 · B10: gravado_por sai do auth.jwt (servidor), nunca do payload do navegador.';

-- 2) DELETE só de administrador --------------------------------------------------
-- Remove qualquer política de DELETE anterior (nomes usados pelos setups antigos)
drop policy if exists atp_analises_hist_del on public.atp_analises_hist;
drop policy if exists atp_hist_del          on public.atp_analises_hist;

create policy atp_analises_hist_del on public.atp_analises_hist
  for delete
  using (
    public.atp_sou_admin()
    and cnpj in (select cnpj from public.atp_empresas
                 where escritorio_id = (select public.atp_meu_escritorio()))
  );

-- 3) Poda preservando 24 versões por empresa/ano ----------------------------------
create or replace function public.atp_hist_poda()
returns trigger language plpgsql security definer set search_path = public as $fn$
begin
  delete from public.atp_analises_hist h
   where h.cnpj = new.cnpj and h.ano = new.ano
     and h.id in (
       select id from public.atp_analises_hist
        where cnpj = new.cnpj and ano = new.ano
        order by gravado_em desc
        offset 24);
  return null;
end $fn$;

drop trigger if exists atp_hist_poda_tg on public.atp_analises_hist;
create trigger atp_hist_poda_tg
  after insert on public.atp_analises_hist
  for each row execute function public.atp_hist_poda();

comment on function public.atp_hist_poda is 'v7.101.1 · B10: preserva as 24 gravações mais recentes por empresa/ano (o app lista 12).';

commit;

-- ═══════════════════════════════════════════════════════════════════════════════
--  TESTE (opcional, não altera nada): usuário comum não apaga histórico.
--  Rode o bloco inteiro — ele termina em ROLLBACK. Troque o e-mail por um usuário
--  com papel 'operador' no seu atp_usuarios.
-- ═══════════════════════════════════════════════════════════════════════════════
-- begin;
-- select set_config('request.jwt.claims',
--        '{"email":"operador@artecon.cnt.br","role":"authenticated"}', true);
-- set local role authenticated;
-- delete from public.atp_analises_hist where id = (select min(id) from public.atp_analises_hist);
-- -- esperado: 0 linhas apagadas (a política de DELETE exige admin).
-- select count(*) as linhas_que_um_operador_conseguiria_apagar
--   from public.atp_analises_hist;  -- deve listar normalmente (SELECT segue liberado)
-- rollback;
