# Fase 0 — Relatório de entrega (18/10/2026)

Implementa as correções imediatas B02–B07 do relatório "Análise Tributária Pro —
Relatório de análise e plano de implantação" (18/10/2026), **sem alterar o motor
nem o lacre**. Partida: v7.99.1, lacre `0a257d66`, suíte com 1249 verificações OK.

## Backup e como voltar

`backup/v7.99.1-2026-10-18/` guarda a cópia byte a byte do `index.html` e do
`tests/run.js` de antes desta rodada, com instruções de restauração no
`LEIA-ME.md`. Commit de referência: `e7c404f`.

## Versões entregues

| Versão | Backlog | O que mudou | Suíte |
| --- | --- | --- | --- |
| v7.99.2 | B02, B03 | Tabela única `PRAZOS_LEGAIS` com as datas da Res. CGSN 194/2026 (Simples 1º/09–15/10, IBS/CBS 1º/09–30/10, regularização 30/10, cancelamento 03/11–20/12, PGDAS-D 20/12 e 20/01; início de atividade 16/10–31/12 e 31/10–31/12); parecer, apresentação e resumos derivam dela. Split payment deixa de ser afirmado como fato: cenário conservador, sem data confirmada (CGIBS, ago/2026), com instrução nova para a IA. | 1262 OK |
| v7.99.3 | B04 | Estado "carregando" na troca de empresa (nenhuma conclusão antes da carga) e bloqueio total em falha de leitura: a análise fica placeholder + `_erroLeitura`, com tarja de erro e botão "Tentar de novo"; `anBloqueada()` corta edição, importação e gravação. | 1270 OK |
| v7.99.4 | B05 | `anSalvar`/`rfSalvar` gravam `motor:{app, lacre}` no resumo; o Dashboard marca "desatualizada" (lacre diferente do atual ou resumo sem carimbo), alerta "valor negativo" e separa o total de economia entre análises no motor atual e desatualizadas. | 1277 OK |
| v7.99.5 | B06, B07 | Elegibilidade declara a fonte da receita e não afirma certeza sobre estimativa (A03); aba Compras/ICMS·IPI harmonizada com a v7.97.0 (A06); lacre "quatro casos" na aba Versões. Desligar a LC 224 exige nº do processo e data da decisão (`cfg.lc224Proc`/`lc224Data`), que herdam entre anos e entram na trilha. | 1287 OK |

Ciclo seguido em cada versão: teste escrito primeiro (vermelho) → menor mudança
no `index.html` → suíte inteira verde → varredura do motor → badge e changelog.

## Varredura do motor (recálculo virtual)

Ferramenta nova `tools/varredura_motor.js`: carrega um `index.html` num sandbox,
roda o `lacreRodar()` e 24 casos pelo motor (4 do lacre, 2 fixtures-gabarito e
18 sintéticos — anexos I–V, Fator R dos dois lados, ST/mono/retenção, sublimite,
limite, LC 224 ligada/desligada, 2025/2026, início de atividade, composição de
fornecedores) e grava ~27,9 mil números com 2 casas num JSON canônico.

```
node tools/varredura_motor.js analise-tributaria-pro/index.html /tmp/atual.json
node tools/varredura_motor.js backup/v7.99.1-2026-10-18/index.html /tmp/base.json
diff <(grep -v '"arquivo"\|"app_versao"' /tmp/base.json) <(grep -v '"arquivo"\|"app_versao"' /tmp/atual.json)
```

Resultado executado após **cada** versão e na conclusão: **v7.99.2, v7.99.3,
v7.99.4 e v7.99.5 reproduzem a v7.99.1 ao centavo em todos os casos** — a única
diferença entre os JSONs é o metadado com o nome do arquivo e a versão do app.
Lacre `0a257d66` ÍNTEGRO em todas.

## Fora desta entrega (dependem de decisão sua)

- **B01** — reabrir/refechar a análise com Presumido negativo (decisão
  profissional, sem código; o Dashboard agora a aponta com o selo "valor negativo").
- **B08 em diante (Fase 1)** — snapshot × recálculo no relatório de análise
  fechada, execução imutável, RLS da conta de teste (B18) etc.
- Decisões 3–5 do relatório: confirmação da Res. 194 no DOU, manter ou retirar
  o cartão de caixa do split, revisão jurídica do A08.
