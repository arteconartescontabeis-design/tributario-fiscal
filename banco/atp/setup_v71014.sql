-- ═══════════════════════════════════════════════════════════════════════════════
--  Análise Tributária Pro v7.101.4 — Perfil de demonstração isolado (B18 · LGPD)
--  Rodar no SQL Editor do Supabase (idempotente: pode rodar mais de uma vez).
--
--  ✅ APLICADO em produção em 21/10/2026 (autorizado pelo escritório). Prova: conta de teste passou a ver 1 empresa (a fictícia) e 0 análises/históricos/consultas; escritório real não vê a fictícia.
--
--  ⚠️ NADA é aplicado pelo aplicativo: este arquivo existe para a SUA revisão e
--  execução manual.
--
--  O PROBLEMA (achado novo 5 da auditoria de 18/10/2026, confirmado em 18/10 por
--  leitura direta do banco): existe um único escritório ("Artecon Artes Contábeis",
--  id 1) e a conta de demonstração teste@artecon.cnt.br está vinculada a ele — ou
--  seja, quem recebe a demonstração enxerga as 263 empresas reais da carteira, com
--  CNPJ, receita e valores. É exposição de dados de clientes (LGPD).
--
--  A CORREÇÃO usa o isolamento multi-tenant que JÁ EXISTE desde a v7.37.0 (RLS por
--  escritorio_id): basta a conta de teste morar num escritório próprio.
--   1) Cria o escritório "Demonstração";
--   2) Move teste@artecon.cnt.br para ele — a partir daí a RLS esconde todas as
--      empresas, análises, históricos e consultas do escritório real;
--   3) Semeia UMA empresa fictícia (claramente rotulada) para a demonstração não
--      abrir vazia — monte a análise de exemplo pelo próprio app, logado na conta
--      de teste, com dados inventados;
--   4) Traz o teste de ACESSO NEGATIVO em BEGIN/ROLLBACK, para provar o isolamento
--      antes de encerrar o chamado.
--
--  Nenhuma empresa real é tocada: não há UPDATE nem DELETE em atp_empresas.
-- ═══════════════════════════════════════════════════════════════════════════════
begin;

-- 1) Escritório de demonstração -------------------------------------------------
insert into public.atp_escritorios (nome)
select 'Demonstração'
 where not exists (select 1 from public.atp_escritorios where nome = 'Demonstração');

-- 2) A conta de teste muda de escritório ----------------------------------------
update public.atp_usuarios
   set escritorio_id = (select id from public.atp_escritorios where nome = 'Demonstração'),
       atualizado_em = now(),
       atualizado_por = 'setup_v71014.sql (B18)'
 where email = 'teste@artecon.cnt.br'
   and escritorio_id is distinct from (select id from public.atp_escritorios where nome = 'Demonstração');

-- 3) Uma empresa fictícia para a demonstração não abrir vazia --------------------
--    (CNPJ inválido de propósito — não colide com empresa real; rótulo explícito)
insert into public.atp_empresas (cnpj, razao_social, regime, analise, situacao, uf, municipio, escritorio_id)
select '11111111000191', 'EMPRESA DEMONSTRAÇÃO LTDA (FICTÍCIA)', 'Simples Nacional', true, 'ATIVA', 'SC', 'Palhoça',
       (select id from public.atp_escritorios where nome = 'Demonstração')
 where not exists (select 1 from public.atp_empresas where cnpj = '11111111000191');

commit;

-- ═══════════════════════════════════════════════════════════════════════════════
--  TESTE DE ACESSO NEGATIVO (não altera nada: termina em ROLLBACK).
--  Rode o bloco inteiro depois do commit acima. Esperado:
--    · empresas_que_a_conta_teste_ve = 1  (só a fictícia)
--    · analises_que_a_conta_teste_ve = 0  (nenhuma análise real)
--  Se qualquer número vier maior, PARE e me avise — a RLS não está isolando.
-- ═══════════════════════════════════════════════════════════════════════════════
-- begin;
-- select set_config('request.jwt.claims',
--        '{"email":"teste@artecon.cnt.br","role":"authenticated"}', true);
-- set local role authenticated;
-- select count(*) as empresas_que_a_conta_teste_ve from public.atp_empresas;
-- select count(*) as analises_que_a_conta_teste_ve from public.atp_analises;
-- select count(*) as historicos_que_a_conta_teste_ve from public.atp_analises_hist;
-- select count(*) as fornecedores_que_a_conta_teste_ve from public.atp_fornec;
-- rollback;

-- ═══════════════════════════════════════════════════════════════════════════════
--  CONTRAPROVA (opcional): um usuário do escritório real NÃO vê a empresa fictícia.
--  Troque o e-mail por um usuário real do escritório Artecon. Esperado: 0.
-- ═══════════════════════════════════════════════════════════════════════════════
-- begin;
-- select set_config('request.jwt.claims',
--        '{"email":"cleiver@artecon.cnt.br","role":"authenticated"}', true);
-- set local role authenticated;
-- select count(*) as ficticias_visiveis_ao_escritorio_real
--   from public.atp_empresas where cnpj = '11111111000191';
-- rollback;
