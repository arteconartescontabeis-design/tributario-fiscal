# Relatório prévio — B16 e B17 (para sua decisão antes de qualquer implementação)

**Data:** 24/10/2026 · **Base:** ATP v7.104.0, lacre do motor `0a257d66` íntegro
**Regra da casa:** mudança que mexa no motor exige relatório prévio + aprovação expressa + re-selo declarado. Este é o relatório. **Nada do B17 foi implementado.**

---

## Parte 1 — B17: projetar a LC 224/2025 nos anos futuros da Reforma

### O que acontece hoje (comportamento atual, verificado no código)

O cenário **"regime regular"** da Reforma (2026–2033) parte do Lucro Presumido **realizado no ano-base** e só troca as parcelas que a Reforma substitui (PIS/COFINS → CBS, ICMS/ISS → IBS, por vigência). A parcela de IRPJ/CSLL viaja **congelada** do ano-base para todos os anos projetados. Consequências com a LC 224/2025 (acréscimo de 10% na presunção sobre a receita acima de R$ 1,25 mi/trimestre):

1. **Análise com ano-base 2025:** a LC 224 não vigora em 2025, então o realizado não tem acréscimo — e os anos projetados **2026 a 2033 saem SEM o acréscimo** que a empresa pagaria de fato. O Presumido projetado fica **subestimado**.
2. **Análise com ano-base 2026:** o realizado tem o acréscimo do IRPJ no ano cheio, mas a CSLL só de abril em diante (noventena da IN RFB 2.305). Os anos projetados **2027+** carregam a CSLL de **3 trimestres** quando o ano projetado cheio teria 4 — subestimação pequena, porém sistemática.
3. **Risco material:** o cenário "regular" escolhe `min(Presumido, Real)` e alimenta o ranking de regimes do parecer. Presumido subestimado pode **vencer indevidamente** o Lucro Real ou o híbrido na comparação dos anos projetados.

### A regra proposta (se você aprovar)

Para cada ano projetado `a ≥ 2026`, recalcular o acréscimo LC 224 **com a vigência daquele ano**, sobre os mesmos trimestres do ano-base (a receita projetada é a realizada — mesma premissa de todo o resto dos cenários):

- `a = 2026`: IRPJ ano cheio + CSLL a partir de abril (como hoje, quando 2026 é o ano-base);
- `a ≥ 2027`: IRPJ e CSLL no ano cheio (4 trimestres);
- `cfg.lc224 === false` (liminar/decisão judicial registrada na Configuração) continua **desligando tudo**, inclusive nos anos projetados;
- o **ano-base realizado nunca muda** — só os anos projetados do cenário "regular".

### O que mexe e o que não mexe

| | |
|---|---|
| **Mexe** | cenário "regular" (regLP → `regular`, `regNome`) dos anos projetados, nas análises acima de R$ 1,25 mi/trimestre |
| **Não mexe** | ano-base realizado · DAS/Simples · cenários "por dentro" e "híbrido" (não envolvem LP) · Lucro Real · análises **fechadas** (a execução congelada da v7.100.0 garante que documento emitido não recalcula) |

### Impacto no lacre — por que precisa da sua aprovação

É **mudança de motor**: o lacre `0a257d66` vai mover e haverá **RE-SELO**. Nos quatro casos-gabarito:

- **Caso 3 (2026, R$ 7,97 mi):** anos projetados 2027+ ganham o complemento da CSLL do 1º trimestre (ordem de grandeza: ~R$ 1,2 mil/ano — o valor exato ao centavo sai do laboratório antes do re-selo);
- **Caso 1 (2025):** se a receita passar de R$ 1,25 mi/trimestre, os anos projetados 2026+ ganham o acréscimo integral;
- **Casos 2 e 4 (abaixo do limite):** idênticos ao centavo.

### Processo de implantação (o mesmo do B13/v7.99.0)

1. Laboratório fora do app mede os deltas ao centavo por caso-gabarito **antes** de tocar o código;
2. teste escrito primeiro na suíte (bloco próprio + caso na suíte independente da lei, seção 1b);
3. implementação mínima; re-selo declarado no changelog com os deltas por caso (padrão v7.99.0);
4. linha nova na Tabela de Regras do Motor (B14) com vigência, fonte e registro da sua aprovação;
5. varredura: diffs **esperados e listados** só nos campos `regular/regLP/regNome` de anos projetados; qualquer diff fora disso aborta.

### Duas perguntas para você

1. **Aprova a mudança e o re-selo?** (sem aprovação, nada é feito — o comportamento atual fica como está)
2. As ADIs 7920/7936/7944/7982 contra a LC 224 seguem pendentes no STF. Quer que o parecer dos anos projetados traga **nota de sensibilidade** ("se a LC 224 cair, o Presumido projetado reduz em R$ X/ano")? É texto, não motor — pode entrar na mesma versão.

---

## Parte 2 — B16: motor único Incorporação/Imobiliária + teste E3

**Diagnóstico: o essencial do B16 já está resolvido.** Nenhuma mudança de motor é necessária; recomendo dar o item por atendido.

1. **Teste E3 (Imobiliária):** já está **verde** — suíte completa 52/52 em 24/10/2026. O ajuste saiu nas versões 1.6.x do módulo (o relatório de 18/10 fotografou o estado anterior).

2. **Incorporação:** o motor único **já é a arquitetura** — `incorporacao/index.html` é **gerado** (`tools/build_incorporacao.js`) copiando do ATP os blocos de motor, Reforma e relatórios, com o mesmo lacre, e a tela confere o lacre cruzado com o index em produção. O que o CI acusava (14 blocos divergentes) era o build desatualizado: as versões v7.100.0–v7.104.0 mudaram blocos copiados sem regerar o arquivo. **Corrigido em 24/10** pelo processo documentado do repositório: rebuild a partir do v7.104.0, suíte 272 OK, motor intocado ("lacre e totais iguais"). O CI continua guardando contra novo desvio.

3. **Imobiliária:** o `motorImob` (lacre próprio `338c914d`) **já recebe as alíquotas do motor genérico do ATP** via contrato (`ctx.aliquotas`, com fonte e classificação declaradas) e aplica apenas as regras do domínio imobiliário — redutores de 50%/70%, redutor de ajuste e social (LC 214, arts. 251–260). Unificar os dois motores num só código **não é recomendado**: as regras são de domínios distintos, o lacre próprio dá rastreabilidade própria, e o risco de regressão supera o benefício (a fonte das alíquotas já é única).

**Se você concordar, o B16 encerra sem mudança de motor** — só com o rebuild já commitado hoje.

---

*Gerado na sessão de implantação do backlog de 18/10/2026 · ATP v7.104.0 · lacre `0a257d66`.*

---

## DESFECHO (24/10/2026)

O escritório **aprovou** a Parte 1 (B17, com a nota de sensibilidade) e a Parte 2 (encerramento do B16), **retirando apenas as duas teses jurídicas do A08** (ISS retido na dedução — decisão 8.9 — e MEI/Simples juntos no crédito de IBS/CBS), que seguem para análise do jurídico — nada foi alterado nesses dois pontos.

**B17 implementado na v7.105.0**, pelo rito: laboratório de deltas antes do código (premissa das parcelas invariantes verificada; candidato de 2026 a partir da base 2025 bateu ao centavo com o realizado verdadeiro de 2026) → bloco 5bp escrito antes, com gabarito transcrito da lei (Δ 22.352,00 no realizado 2026 e 23.936,00 no ano cheio, caso uniforme de 600 mil/mês) → implementação mínima no `calcCenariosReforma` → **lacre re-selado `0a257d66` → `795f5d26`** com os deltas declarados no changelog (caso 3: regular 2027–2033 **+689,93 cada**; casos 1, 2 e 4, totais anuais e cenários dentro/híbrido idênticos ao centavo) → varredura de 24 casos: diffs **apenas** em `regular`/`regLP` de anos projetados (222 + 74 linhas), nenhum mês, total ou cenário dentro/híbrido tocado. Suíte: 1378 OK · Incorporação regerada: 272 OK · Imobiliária: 71/71.
