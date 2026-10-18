# Fase 1 (parte 1) — Relatório de entrega (18/10/2026)

Continuação da Fase 0 (v7.99.2–v7.99.5). Implementa **B08 a B12 e B18** do
relatório de 18/10/2026, **sem alterar o motor nem o lacre** (`0a257d66`).
Partida desta rodada: v7.99.5, suíte com 1287 verificações OK.

## Versões entregues

| Versão | Backlog | O que mudou | Suíte |
| --- | --- | --- | --- |
| v7.100.0 | B08 | **Relatório de análise fechada sai do snapshot** (decisão B08, recomendação do relatório): o fechamento grava a execução completa (resultado + cenários congelados em `res.__cen` + base projetada); Relatórios, parecer e conferência de análise fechada leem o fechamento — o documento emitido não muda quando o motor muda. Fechamentos antigos (sem execução) seguem no recálculo, com aviso. Botão **🔁 Refechar com o motor atual** (evento *refechada* no histórico). Rodapé do parecer declara o motor do fechamento. Guardas de versão da suíte relaxadas para o minor de 3 dígitos. | 1296 OK |
| v7.101.0 | B09 | **Registro imutável de execuções**: salvar/fechar/refechar inserem na tabela nova `atp_execucoes` (quem, quando, app, lacre, totais, cenários 2033, hashes dos parâmetros). `setup_v7101.sql` para revisão: só INSERT+SELECT por RLS e trigger recusando UPDATE/DELETE. Visor **📜 Execuções** na análise. Sem o SQL, nada quebra. | 1304 OK |
| v7.101.1 | B10 | **Histórico robusto**: 12 versões na tela (24 preservadas no banco); `setup_v71011.sql` para revisão: autor gravado pelo servidor (trigger lê `auth.jwt`), DELETE só de admin (`atp_sou_admin`), poda SECURITY DEFINER, teste em BEGIN/ROLLBACK provando que usuário comum não apaga. | 1309 OK |
| v7.101.2 | B11 | **Teste automático de consistência entre telas** (bloco 5bi): cartões da Análise = `totExib` ao centavo; resumo gravado (Dashboard) e parecer ≤ R$ 0,06 dos cartões; cenários 2033 do parecer idênticos ao `calcCenariosReforma` do mesmo resultado. Divergência medida hoje: **R$ 0,0000**. O CI falha na próxima mudança que quebrar a convergência. | 1316 OK |
| v7.101.3 | B12 | **Rodapé rastreável**: Consolidado, Conferência, Comparativo de Regimes e Reforma imprimem a execução de origem (motor atual, ou execução congelada do fechamento + versão que imprimiu); apresentação declara na tela "Sobre"; parecer já declarava desde a v7.100.0. Nenhum PDF sai sem dizer qual execução o produziu. | 1322 OK |
| v7.101.4 | B18 | **Perfil de demonstração isolado (LGPD)** — confirmado por leitura direta do banco: um único escritório e `teste@artecon.cnt.br` vinculado a ele, vendo as 263 empresas reais. `setup_v71014.sql` para revisão: escritório "Demonstração", conta de teste movida (a RLS da v7.37.0 esconde a carteira real), empresa fictícia rotulada, teste de acesso negativo em BEGIN/ROLLBACK. Nenhuma empresa real é tocada. | 1327 OK |

## O que você precisa fazer (SQL — nada foi aplicado no Supabase)

Os três scripts são **idempotentes** e esperam a sua revisão e execução manual,
nesta ordem sugerida (o app funciona normalmente sem eles):

1. **`banco/atp/setup_v71014.sql`** — URGENTE (LGPD): isola a conta de
   demonstração. Rode também o teste de acesso negativo do rodapé do arquivo.
2. **`banco/atp/setup_v7101.sql`** — liga o registro imutável de execuções.
3. **`banco/atp/setup_v71011.sql`** — endurece o histórico (autor pelo servidor,
   DELETE só de admin, retenção 24). Antes de rodar, confira triggers de poda
   antigos com a consulta indicada no cabeçalho do arquivo.

## Varredura do motor

Executada após **cada** versão e na conclusão (`tools/varredura_motor.js`,
24 casos, ~27,9 mil números): **v7.100.0 a v7.101.4 reproduzem a v7.99.1 ao
centavo em todos os casos**; lacre `0a257d66` ÍNTEGRO em todas. O backup
`backup/v7.99.1-2026-10-18/` continua valendo como ponto de retorno exato.

## O que falta da Fase 1 (próxima rodada)

- **B13** — suíte independente (15–20 casos calculados fora do motor, com fonte legal).
- **B14** — tabela de regras com vigência, fonte e aprovador.
- **B15** — regime tributário por ano (cadastro único, fase 2).
- **B16** — motor único Incorporação/Imobiliária; corrigir teste E3.
- **B17** — projetar a LC 224 em anos futuros na Reforma.
- E as decisões suas que seguem em aberto: **B01** (reabrir/refechar a análise
  com Presumido negativo — com a v7.100.0, o 🔁 Refechar faz isso em um clique,
  e o Dashboard aponta a linha), confirmação da Res. 194 no DOU, cartão do
  split e revisão jurídica do A08.
