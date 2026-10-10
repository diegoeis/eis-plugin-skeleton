# eis-setup-plugin

Plugin para Claude Code e Cowork que cria a estrutura de pastas de um projeto de plugin, separando o que é projeto do que é plugin.

## Instalar

```
/plugin marketplace add diegoeis/eis-plugins
/plugin install eis-setup-plugin@eis-plugins
```

## Skills

| Skill | O que faz |
| --- | --- |
| [`init`](src/skills/init) | Cria um projeto de plugin novo a partir do template: `src/`, `docs/`, `scripts/pack.sh`, README, AGENTS.md e CLAUDE.md. |

Uso: `/eis-setup-plugin:init [caminho-da-pasta]`

## A estrutura criada

```
meu-plugin/
├── src/                    raiz do plugin: só o que vai para o pacote
│   ├── .claude-plugin/plugin.json
│   └── skills/
├── docs/                   especificações e documentação do projeto
├── scripts/
│   ├── pack.sh             gera o pacote em dist/
│   └── pii-patterns.txt    padrões proibidos dentro de src/
├── dist/                   builds (fora do git)
│   ├── vX.Y.Z/
│   └── vX.Y.Z.zip
├── AGENTS.md
├── CLAUDE.md               importa o AGENTS.md
└── README.md
```

`pack.sh` lê `name` e `version` de `src/.claude-plugin/plugin.json`, roda `claude plugin validate`, procura em `src/` os padrões de `scripts/pii-patterns.txt` e gera `dist/vX.Y.Z/` e `dist/vX.Y.Z.zip`. Ele para se a versão já existir.

Este repositório usa a mesma estrutura: o plugin está em `src/`.

## Desenvolver este plugin

```
claude --plugin-dir ./src     # testar
./scripts/pack.sh             # empacotar
```
