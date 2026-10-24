# Backup — Análise Tributária Pro v7.99.1 (18/10/2026)

Cópia exata do app e da suíte ANTES das melhorias da Fase 0 (relatório de 18/10/2026).

- `index.html` — app v7.99.1, lacre `0a257d66` (cópia byte a byte de `analise-tributaria-pro/index.html`)
- `run.js` — suíte com 1249 verificações OK (cópia byte a byte de `tests/run.js`)
- Commit git de referência: `e7c404f` (estado do repositório antes desta rodada)

## Como voltar exatamente para hoje

```
cp backup/v7.99.1-2026-10-18/index.html analise-tributaria-pro/index.html
cp backup/v7.99.1-2026-10-18/run.js tests/run.js
```

Ou, pelo git: `git checkout e7c404f -- analise-tributaria-pro/index.html tests/run.js`
