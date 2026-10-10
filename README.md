# eis-setup-plugin

Plugin for Claude Code and Cowork that creates the folder structure of a plugin project, keeping what belongs to the project apart from what belongs to the plugin.

## Install

```
/plugin marketplace add diegoeis/eis-plugins
/plugin install eis-setup-plugin@eis-plugins
```

## Skills

| Skill | What it does |
| --- | --- |
| [`init`](src/skills/init) | Creates a new plugin project from the template: `src/`, `docs/`, `scripts/pack.sh`, README, AGENTS.md and CLAUDE.md. |

Usage: `/eis-setup-plugin:init [folder-path]`

## The structure it creates

```
my-plugin/
├── src/                    plugin root: only what goes into the package
│   ├── .claude-plugin/plugin.json
│   └── skills/
├── docs/                   project specs and documentation
├── scripts/
│   ├── pack.sh             builds the package into dist/
│   ├── pii-patterns.example.txt   template for the pattern list
│   └── pii-patterns.txt    patterns forbidden in src/ (local, out of git)
├── dist/                   builds (out of git)
│   ├── vX.Y.Z/
│   └── vX.Y.Z.zip
├── AGENTS.md
├── CLAUDE.md               imports AGENTS.md
└── README.md
```

`pack.sh` reads `name` and `version` from `src/.claude-plugin/plugin.json`, runs `claude plugin validate`, searches `src/` for the patterns in `scripts/pii-patterns.txt` (a local file, out of git; the template is `pii-patterns.example.txt`) and builds `dist/vX.Y.Z/` and `dist/vX.Y.Z.zip`. It stops if the version already exists.

This repository uses the same structure: the plugin lives in `src/`.

## Developing this plugin

```
claude --plugin-dir ./src     # test
./scripts/pack.sh             # package
```
