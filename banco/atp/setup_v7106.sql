-- ═══════════════════════════════════════════════════════════════════════════════
--  Análise Tributária Pro v7.106.0 — Plano de apuração do cliente (ciclo de entrega)
--  Rodar no SQL Editor do Supabase (idempotente: pode rodar mais de uma vez).
--
--  ✅ APLICADO em produção em 24/10/2026 (autorizado pelo escritório). Prova: information_schema
--     mostra a coluna plano_apuracao (text) em atp_empresas.
--
--  O QUE É: cada cliente tem um plano com a Artecon — análise ANUAL, SEMESTRAL ou
--  TRIMESTRAL. A ficha da empresa ganha a coluna plano_apuracao, e a aba Relatórios
--  passa a abrir o "Período do documento" no último período do plano com receita
--  lançada. O corte do documento é a SOMA dos meses do período, apurados pelo motor
--  mensal (IRPJ/CSLL do Presumido, adicional e LC 224 são trimestrais — cortes
--  alinhados a trimestre são exatos). Nenhum cálculo muda: a coluna só orienta a
--  tela. Cada entrega fica registrada no Histórico (evento entrega-periodo).
--
--  Sem esta coluna o app segue funcionando: o seletor abre em "Ano completo" e o
--  salvar da ficha avisa para rodar este setup.
-- ═══════════════════════════════════════════════════════════════════════════════
begin;

alter table public.atp_empresas
  add column if not exists plano_apuracao text
  check (plano_apuracao in ('trimestral','semestral','anual'));

comment on column public.atp_empresas.plano_apuracao is
  'v7.106.0 · Plano do cliente com a Artecon (ciclo de entrega das análises): trimestral, semestral ou anual (nulo = anual). Orienta o Período do documento na aba Relatórios; não altera cálculo algum.';

commit;

-- Conferência (não altera nada): a coluna deve aparecer com o tipo text.
-- select column_name, data_type from information_schema.columns
--  where table_schema = 'public' and table_name = 'atp_empresas' and column_name = 'plano_apuracao';
