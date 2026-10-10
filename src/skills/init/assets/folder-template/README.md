# {{PLUGIN_NAME}}

{{PLUGIN_DESCRIPTION}}

## Estrutura

```
{{PLUGIN_NAME}}/
├── src/                    raiz do plugin: só o que vai para o pacote
│   ├── .claude-plugin/plugin.json
│   └── skills/
├── docs/                   especificações e documentação do projeto
├── scripts/
│   ├── pack.sh             gera o pacote em dist/
│   └── pii-patterns.txt    padrões proibidos dentro de src/
├── dist/                   builds gerados (fora do git)
├── AGENTS.md
├── CLAUDE.md
└── README.md
```

## Desenvolver

Coloque skills, agents, hooks e demais arquivos do plugin dentro de `src/`, seguindo o [layout padrão de plugins](https://code.claude.com/docs/en/plugins-reference#standard-layout).

Para testar sem empacotar:

```
claude --plugin-dir ./src
```

## Empacotar

1. A partir do segundo pacote, suba `version` em `src/.claude-plugin/plugin.json` (o primeiro sai como `0.1.0`).
2. Rode:

```
./scripts/pack.sh
```

O script valida o plugin com `claude plugin validate`, procura em `src/` os padrões listados em `scripts/pii-patterns.txt` e gera:

- `dist/vX.Y.Z/` — cópia limpa de `src/`
- `dist/vX.Y.Z.zip` — o zip dessa pasta, pronto para importar

Ele para se a versão já existir em `dist/`.
