# Tributário e Fiscal — aplicativos da Artecon

Repositório do departamento **Tributário e Fiscal** (Portal: área `tributario`).
Cada aplicativo fica numa pasta com o seu `index.html` e é publicado pelo GitHub Pages em
`https://arteconartescontabeis-design.github.io/tributario-fiscal/<pasta>/`.

| Aplicativo (Portal) | Pasta | Banco (Supabase) | Funções do servidor |
|---|---|---|---|
| Análise Tributária Pro (`atp`) | `analise-tributaria-pro/` | analise-tributaria-pro (`kmdrqkiyhdmdtufrogke`) | gerar-parecer, admin-senha, admin-usuario, atualizar-classtrib, cff-consulta |
| Classificação RTC (`rtc`) | `classificacao-rtc/` | o mesmo | — |
| Análise Imobiliária (`imobiliario`) | `imobiliario/` | o mesmo | gerar-parecer-imobiliario |
| Simulação de Incorporação (`incorporacao`) | `incorporacao/` (**gerado**) | o mesmo | gerar-parecer-incorporacao |
| NCM Pro (`ncm`) | `ncm-pro/` | o mesmo (tabelas `ncm_*`) | ncm-claude-proxy |

Todos os aplicativos do departamento usam **um banco e um login**: o do projeto `analise-tributaria-pro`.

## Regras
- **Nenhum segredo no código.** A chave publicável do Supabase é pública por natureza (a proteção é a RLS).
  Senhas, service role e tokens ficam só nos secrets do Supabase.
- O código oficial das funções do servidor fica no repositório **privado** `artecon-supabase`
  (`projetos/analise-tributaria-pro/functions/`). Aqui ficam só as cópias que os testes leem.
- `incorporacao/index.html` **não se edita à mão**: edite `incorporacao/src/` e rode `node tools/build_incorporacao.js`.
- Mudança de banco: script em `banco/`, conferir o backup do dia antes de aplicar.

## Testes
```
node tests/run.js                 # Análise Tributária Pro (motor + lacre)
node tests/run_incorporacao.js    # Simulação de Incorporação (motor copiado = motor do ATP)
npm i --no-save jsdom@24 && node tests/run_imob_ui.js   # Análise Imobiliária
```
Rodam também no GitHub Actions a cada envio.

## Origem
Migrado em 10/2026 a partir dos repositórios `analise-tributaria-pro` (commit `e41acb2`) e `ncm-pro` (commit `754621b`),
que ficam arquivados com todo o histórico anterior. Plano e decisões: `artecon-supabase/docs/`.
