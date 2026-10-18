-- ═══════════════════════════════════════════════════════════════════════════════
--  Análise Tributária Pro v7.101.0 — Registro de execuções (B09, execução imutável)
--  Rodar no SQL Editor do Supabase (idempotente: pode rodar mais de uma vez).
--
--  ⚠️ NADA é aplicado pelo aplicativo: este arquivo existe para a SUA revisão e
--  execução manual. Sem ele o app segue funcionando normalmente — apenas avisa no
--  console, uma vez por sessão, que a execução não foi registrada.
--
--  O QUE É: cada gravação que produz números (salvar, fechar, refechar) deixa um
--  registro IMUTÁVEL — quando, quem, com que motor (app + lacre), com que parâmetros
--  (impressões digitais em hash) e que totais saíram. É a base de auditoria da
--  Prioridade 1 do relatório de 18/10/2026: prova, meses depois, qual execução
--  produziu o número entregue, e alimenta a comparação mês a mês.
--
--  IMUTABILIDADE EM DUAS CAMADAS:
--   1) RLS só com políticas de SELECT e INSERT — não existe política de UPDATE nem
--      de DELETE, então a API não consegue alterar nem apagar linha alguma;
--   2) trigger que recusa UPDATE/DELETE para qualquer caminho que chegue à tabela
--      (inclusive o console). Para manutenção excepcional, remova antes o trigger:
--      drop trigger atp_execucoes_bloqueio on public.atp_execucoes;
-- ═══════════════════════════════════════════════════════════════════════════════
begin;

create table if not exists public.atp_execucoes (
  id       bigint generated always as identity primary key,
  cnpj     text        not null,
  ano      integer     not null,
  em       timestamptz not null default now(),
  origem   text        not null check (origem in ('salvar','fechar','refechar')),
  app      text        not null,
  lacre    text        not null,
  usuario  text,
  totais   jsonb       not null,
  cen2033  jsonb,
  params   jsonb
);

comment on table  public.atp_execucoes         is 'Registro imutável de execuções do motor (v7.101.0 · B09): uma linha por gravação (salvar/fechar/refechar), com motor (app + lacre), parâmetros (hashes) e totais. Só INSERT e SELECT; UPDATE/DELETE recusados por política e por trigger.';
comment on column public.atp_execucoes.origem  is 'O que gravou: salvar (anSalvar), fechar (anFecharAbrir) ou refechar (anRefecharCore).';
comment on column public.atp_execucoes.app     is 'APP_VERSAO que executou o cálculo.';
comment on column public.atp_execucoes.lacre   is 'LACRE_HASH do motor na execução.';
comment on column public.atp_execucoes.totais  is 'Totais do ano: receita, simples, lp, lr, das, lrIncompleto.';
comment on column public.atp_execucoes.cen2033 is 'Cenários 2033: dentro, hib, regular (quando calculáveis).';
comment on column public.atp_execucoes.params  is 'Impressões digitais (hash 8 hex) dos parâmetros em uso: anexos, folha, reforma e cfg da análise.';

create index if not exists atp_execucoes_cnpj_ano_em on public.atp_execucoes (cnpj, ano, em desc);

alter table public.atp_execucoes enable row level security;

drop policy if exists atp_execucoes_sel on public.atp_execucoes;
drop policy if exists atp_execucoes_ins on public.atp_execucoes;

create policy atp_execucoes_sel on public.atp_execucoes
  for select
  using (
    cnpj in (select cnpj from public.atp_empresas
             where escritorio_id = (select public.atp_meu_escritorio()))
  );

create policy atp_execucoes_ins on public.atp_execucoes
  for insert
  with check (
    cnpj in (select cnpj from public.atp_empresas
             where escritorio_id = (select public.atp_meu_escritorio()))
  );

-- sem política de UPDATE nem de DELETE: pela API, a linha é só-leitura depois de inserida

create or replace function public.atp_execucoes_imutavel()
returns trigger language plpgsql as $fn$
begin
  raise exception 'atp_execucoes é registro imutável (v7.101.0 · B09): UPDATE e DELETE são recusados. Para manutenção excepcional, remova antes o trigger atp_execucoes_bloqueio.';
end $fn$;

drop trigger if exists atp_execucoes_bloqueio on public.atp_execucoes;
create trigger atp_execucoes_bloqueio
  before update or delete on public.atp_execucoes
  for each row execute function public.atp_execucoes_imutavel();

commit;
